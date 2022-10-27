local flib_direction = require("__flib__.direction")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_table = require("scripts.util.table")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local logger = require("scripts.lib.logger")

local TrainsConstructor = {}

function TrainsConstructor.init()
    TrainsConstructor._register_event_handlers()
end

function TrainsConstructor.load()
    TrainsConstructor._register_event_handlers()
end

---@param data NthTickEventData
function TrainsConstructor._construct(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(TrainsConstructor._get_contexts_from_tasks()) do
        TrainsConstructor._deploy_trains_for_context(context, data)
    end
end

function TrainsConstructor._get_contexts_from_tasks()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        table.insert(contexts, Context.from_model(task))
    end

    return contexts
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function TrainsConstructor._deploy_trains_for_context(context, data)
    if not persistence_storage.is_depot_exists_at(context) then
        -- todo remove formed tasks if depot was destroyed and reset all finished tasks
        return
    end

    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_form_tasks_ready_for_deploy(context)

    ---@param task scripts.lib.domain.entity.task.TrainFormTask
    for _, task in pairs(tasks) do
        TrainsConstructor._try_deploy_train(context, task, tick)
    end
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function TrainsConstructor._try_deploy_train(context, task, tick)
    if task:is_state_formed() and not TrainsConstructor._is_deploy_slot_free(context) then
        return
    end

    TrainsConstructor._deploy_train(context, task, tick)
end

---@param context scripts.lib.domain.Context
---@return bool
function TrainsConstructor._is_deploy_slot_free(context)
    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)

    return depot_station_output.connected_rail.trains_in_block == 0
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function TrainsConstructor._deploy_train(context, task, tick)
    local task_changed = false

    if task:is_state_formed() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
        task:state_deploy(train_template)
        task_changed = true

        logger.debug("Try deploy train for template {1}", {task.train_template_id}, "depot")
    end

    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)

    if depot_station_output == nil then
        logger.warning("Depot station for context {1} is nil", {tostring(context)}, "depot")
    end

    local train_template = task.train_template
    local force = game.forces[task.force_name]
    local surface = game.surfaces[task.surface_name]
    local x_train, y_train = atd.defines.rotate_relative_position[depot_station_output.direction](-2, 3)
    local train_position = {
        x = depot_station_output.position.x + x_train,
        y = depot_station_output.position.y + y_train,
    }
    local main_locomotive = task:get_main_locomotive()
    local result_train_length = main_locomotive ~= nil and #main_locomotive.train.carriages or 0
    local target_train_length = #train_template.train

    if task:is_state_deploy() and result_train_length ~= target_train_length then
        -- try build next train part

        ---@type scripts.lib.domain.entity.template.RollingStock
        local train_part = train_template.train[task.deploy_cursor]

        local carrier_direction
        if train_part.direction == atd.defines.train.direction.in_direction then
            carrier_direction = depot_station_output.direction
        else
            carrier_direction = flib_direction.opposite(depot_station_output.direction)
        end

        local entity_data = {
            name = train_part.prototype_name,
            position = train_position,
            direction = carrier_direction,
            force = force,
        };

        if surface.can_place_entity(entity_data) then
            local carrier = surface.create_entity(entity_data)

            if train_part:is_locomotive() then
                if task.deploy_cursor == 1 then
                    task:set_main_locomotive(carrier)

                    TrainsConstructor._add_train_schedule(task.main_locomotive.train, train_template)
                end

                -- todo fill by fuel from template
                local inventory = carrier.get_inventory(defines.inventory.fuel)
                inventory.insert({name = "coal", count = 50})
            end

            carrier.train.manual_mode = false

            task:deploy_cursor_next()

            task_changed = true
        end

    elseif task:is_state_deploy() and result_train_length == target_train_length then
        TrainsConstructor._register_train_for_template(main_locomotive.train, train_template)

        task:state_completed(tick)

        task_changed = true
    end

    if task_changed then
        persistence_storage.trains_tasks.add(task)

        TrainsConstructor._raise_task_changed_event(task)
    end

end

---@param train_task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function TrainsConstructor._raise_task_changed_event(train_task)
    -- todo duplicity

    ---@type LuaForce
    local force = game.forces[train_task.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
            atd.defines.events.on_core_train_task_changed,
            { train_task_id = train_task.id, player_index = player.index }
        )
    end

end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param lua_train LuaTrain
function TrainsConstructor._register_train_for_template(lua_train, train_template)
    local train = persistence_storage.find_train(lua_train.id)

    train:set_train_template(train_template)

    persistence_storage.add_train(train)
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param train LuaTrain
function TrainsConstructor._add_train_schedule(train, train_template)
    train.schedule = util_table.deep_copy(train_template.destination_schedule)
    train.manual_mode = false
end

function TrainsConstructor._trains_constructor_check_activity()
    if persistence_storage.trains_tasks.count_form_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, TrainsConstructor._construct)
    end
end

---@param event EventData
function TrainsConstructor._handle_trains_constructor_check_activity(event)
    TrainsConstructor._trains_constructor_check_activity()
end

function TrainsConstructor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return TrainsConstructor._handle_trains_constructor_check_activity(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "TrainsConstructor")
    end
end

return TrainsConstructor