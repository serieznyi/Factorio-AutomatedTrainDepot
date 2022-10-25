local flib_table = require("__flib__.table")
local flib_direction = require("__flib__.direction")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local trains_balancer = require("scripts.lib.trains_balancer")
local logger = require("scripts.lib.logger")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local TrainFormingTask = require("scripts.lib.domain.entity.task.TrainFormingTask")

local public = {}
local private = {}
local forming = {}
local deploy = {}

local rotate_relative_position = {
    [defines.direction.north] = function(x, y)
        return x, y
    end,
    [defines.direction.east] = function(x, y)
        return y * -1, x
    end,
    [defines.direction.south] = function(x, y)
        return x * -1, y * -1
    end,
    [defines.direction.west] = function(x, y)
        return y, x * -1
    end,
}

---------------------------------------------------------------------------
-- -- -- FORMING
---------------------------------------------------------------------------

function forming.get_contexts_from_tasks()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        table.insert(contexts, Context.from_model(task))
    end

    return contexts
end

---------------------------------------------------------------------------
-- -- -- DEPLOY
---------------------------------------------------------------------------

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function deploy.try_deploy_train(context, task, tick)
    if task:is_state_formed() and not deploy.is_deploy_slot_free(context) then
        return
    end

    deploy.deploy_train(context, task, tick)
end

---@param task scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function deploy.try_remove_completed_task(task, tick)
    if not task:is_state_completed() then
        return
    end

    local completed_since = tick - task.completed_at

    if completed_since > atd.defines.time_in_ticks.seconds_2 then
        task:delete()

        persistence_storage.trains_tasks.add(task)

        private.raise_task_changed_event(task)
    end
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function deploy.deploy_train(context, task, tick)
    if task:is_state_formed() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
        task:start_deploy(train_template)
        persistence_storage.trains_tasks.add(task)

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
    local x_train, y_train = rotate_relative_position[depot_station_output.direction](-2, 3)
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
        local train_part = train_template.train[task.deploying_cursor]

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
                if task.deploying_cursor == 1 then
                    task:set_main_locomotive(carrier)

                    private.add_train_schedule(task.main_locomotive.train, train_template)
                end

                -- todo fill by fuel from template
                local inventory = carrier.get_inventory(defines.inventory.fuel)
                inventory.insert({name = "coal", count = 50})
            end

            carrier.train.manual_mode = false

            task:deploying_cursor_next()
        end

    elseif task:is_state_deploy() and result_train_length == target_train_length then
        private.register_train_for_template(main_locomotive.train, train_template)

        task:complete(tick)
    end

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)
end

---@param context scripts.lib.domain.Context
---@return bool
function deploy.is_deploy_slot_free(context)
    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)

    return depot_station_output.connected_rail.trains_in_block == 0
end

---@param data NthTickEventData
function deploy.deploy_trains(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(forming.get_contexts_from_tasks()) do
        deploy.deploy_trains_for_context(context, data)
    end

    if persistence_storage.trains_tasks.count_forming_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, nil)
    end
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function deploy.deploy_trains_for_context(context, data)
    if not persistence_storage.is_depot_exists_at(context) then
        -- todo remove formed tasks if depot was destroyed and reset all finished tasks
        return
    end

    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_forming_tasks_ready_for_deploy(context)

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(tasks) do
        deploy.try_deploy_train(context, task, tick)
    end
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param train_task scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
function private.raise_task_changed_event(train_task)
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

---@param train_task scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
function private.raise_task_deleted_event(train_task)
    -- todo duplicity
    logger.debug(
            "Deleted train task (`1`) `{2}` for template `{3}`",
            { train_task.type, train_task.id, train_task.train_template_id },
            "depot"
    )

    ---@type LuaForce
    local force = game.forces[train_task.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
                atd.defines.events.on_core_train_task_deleted,
                { train_task_id = train_task.id, player_index = player.index }
        )
    end

end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param train LuaTrain
function private.add_train_schedule(train, train_template)
    train.schedule = flib_table.deep_copy(train_template.destination_schedule)
    train.manual_mode = false
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param lua_train LuaTrain
function private.register_train_for_template(lua_train, train_template)
    local train = persistence_storage.find_train(lua_train.id)

    train:set_train_template(train_template)

    persistence_storage.add_train(train)
end

function private.get_depot_multiplier()
    return 1.0 -- todo depended from technologies
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
---@return void
function private.try_bind_train_template_with_disband_task(task)
    local train_id = task.train_id
    local train = persistence_storage.find_train(train_id)

    if train.train_template_id ~= nil then
        task:bind_with_template(train.train_template_id)

        persistence_storage.trains_tasks.add(task)
    end
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return scripts.lib.domain.entity.Train
function private._try_choose_train_for_disband(train_template)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)

    -- todo add more logic for getting train (empty train, train in depot, ...)
    return #trains > 0 and trains[1] or nil
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function private.process_disbanding_task(task, tick)
    if task:is_state_created() and task.train_template_id == nil then
        private.try_bind_train_template_with_disband_task(task)
    end

    if task:is_state_created() then

    end

    -- todo
end

---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function private.process_forming_task(task, tick)
    local multiplier = private.get_depot_multiplier()

    if not task:is_state_created() and not task:is_state_form() then
        return false
    end

    if task:is_state_created() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)

        task:start_forming(tick, multiplier, train_template)
    end

    if task:is_forming_time_left(tick) then
        task:state_formed()
    end

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    if task:is_state_formed() then
        -- todo raise event
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, deploy.deploy_trains)
    end

    return true
end

---@param data NthTickEventData
function private.train_manipulations(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        if task.type == TrainFormingTask.type then
            private.process_forming_task(task, tick)
        elseif task.type == TrainDisbandTask.type then
            private.process_disbanding_task(task, tick)
        end

        deploy.try_remove_completed_task(task, data.tick)
    end

    if persistence_storage.trains_tasks.total_count_forming_tasks() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, nil)
    end
end

function private.on_ntd_trains_manipulation()
    script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, private.train_manipulations)
end

---@param e scripts.lib.event.Event
function private._handle_trains_manipulations(e)
    private.on_ntd_trains_manipulation()
end

function private._handle_trains_balancer_check_activity(e)
    private.trains_balancer_check_activity()
end

function private.trains_balancer_check_activity()

    if persistence_storage.count_active_trains_templates() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, nil)
        logger.debug("Pause trains balancer", {}, "depot")
    else
        script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, trains_balancer.balance_trains_quantity)
        logger.debug("Start trains balancer", {}, "depot")
    end
end

function private.register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_deleted),
            handler = function(e) return private._handle_trains_manipulations(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_added),
            handler = function(e) return private._handle_trains_manipulations(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = function(e) return private._handle_trains_balancer_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_changed),
            handler = function(e) return private._handle_trains_balancer_check_activity(e) end,
        }
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "depot")
    end
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    private.register_event_handlers()
end

function public.load()
    private.register_event_handlers()
end

---@param schedule TrainSchedule
function public.is_valid_schedule(schedule)
    local is_path_readable = false

    -- todo add realisation

    return is_path_readable
end

return public