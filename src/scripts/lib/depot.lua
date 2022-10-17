local flib_table = require("__flib__.table")
local flib_direction = require("__flib__.direction")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local TrainFormingTask = require("scripts.lib.domain.entity.task.TrainFormingTask")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local train_service = require("scripts.lib.train_service")
local persistence_storage = require("scripts.persistence.persistence_storage")
local logger = require("scripts.lib.logger")

local public = {}
local private = {}
local forming = {}
local disband = {}
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

function forming.get_forming_slots_total_count()
    return 2 -- todo depend from technologies
end

---@param context scripts.lib.domain.Context
---@return bool
function forming.has_free_forming_slot(context)
    local tasks_count = persistence_storage.trains_tasks.count_forming_tasks(context)
    local slots_count = forming.get_forming_slots_total_count()

    return slots_count > tasks_count
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function forming.try_add_forming_train_task_for_template(train_template)
    -- todo balance tasks for different forces, surfaces and templates
    local context = Context.from_model(train_template)

    if not forming.has_free_forming_slot(context) then
        return false
    end

    local forming_task = TrainFormingTask.from_train_template(train_template)

    persistence_storage.trains_tasks.add(forming_task)

    logger.debug(
            "Add new forming task `{1}` for template `{2}`",
            { forming_task.id, train_template.name },
            "depot"
    )

    return true
end

function forming.get_forming_tasks_contexts()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_forming_tasks()

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(tasks) do
        local context = Context.from_model(task)
        if persistence_storage.is_depot_exists_at(context) then
            table.insert(contexts, context)
        end
    end

    return contexts
end

---@param task scripts.lib.domain.entity.task.TrainFormingTask
function forming.discard_forming_task(task)
    task:delete()

    -- todo discard reserved inventory items

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    logger.debug(
            "Discard train forming task `{1}` for template `{2}`",
            { task.id, task.train_template_id},
            "depot"
    )
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function forming.try_discard_forming_train_task_for_template(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.trains_tasks.find_forming_tasks(
            context,
            train_template.id
    )

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(tasks) do
        if task:is_state_forming() or task:is_state_created() then
            forming.discard_forming_task(task)

            return true
        end
    end

    return false
end

---------------------------------------------------------------------------
-- -- -- DISBAND
---------------------------------------------------------------------------

function disband.get_disband_slots_total_count()
    return 2 -- todo depend from technologies
end

---@param context scripts.lib.domain.Context
---@return bool
function disband.has_free_disband_slot(context)
    local tasks_count = persistence_storage.trains_tasks.count_disband_tasks(context)
    local slots_count = disband.get_disband_slots_total_count()

    return slots_count > tasks_count
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function disband.try_add_disband_train_task_for_template(train_template)
    -- todo balance tasks for different forces, surfaces and templates
    local context = Context.from_model(train_template)

    if not disband.has_free_disband_slot(context) then
        return false
    end

    ---@type scripts.lib.domain.entity.Train
    local train = disband.try_get_train_for_disband(train_template)

    if train == nil then
        return false
    end

    local task = TrainDisbandTask.from_train(train)

    persistence_storage.trains_tasks.add(task)

    logger.debug(
            "Add new disband task `{1}` for template `{2}` and train `{3}`",
            { task.id, train_template.name, train.id },
            "depot"
    )

    return true
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return scripts.lib.domain.entity.Train
function disband.try_get_train_for_disband(train_template)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)

    return #trains > 0 and trains[1] or nil
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function disband.discard_disbanding_task(task)
    task:delete()

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    logger.debug(
            "Discard train disband task `{1}` for template `{2}`",
            { task.id, task.train_template_id},
            "depot"
    )
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function disband.try_discard_disbanding_train_task_for_template(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.trains_tasks.find_disbanding_tasks(context, train_template.id)

    ---@param task scripts.lib.domain.entity.task.TrainDisbandTask
    for _, task in pairs(tasks) do
        if task:is_state_created() then
            forming.discard_forming_task(task)

            return true
        end
    end

    return false
end

---------------------------------------------------------------------------
-- -- -- DEPLOY
---------------------------------------------------------------------------

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function deploy.try_deploy_train(context, task, tick)
    if task:is_state_formed() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
        task:start_deploy(train_template)
        persistence_storage.trains_tasks.add(task)

        logger.debug("Try deploy train for template {1}", {task.train_template_id}, "depot")
    end

    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)
    ---@type LuaEntity
    local depot_station_signal = remote.call("atd", "depot_get_output_signal", context)

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

    if task:is_state_deploying() and  result_train_length ~= target_train_length then
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

                -- add fuel todo fill by fuel from template
                local inventory = carrier.get_inventory(defines.inventory.fuel)
                inventory.insert({name = "coal", count = 50})

                -- todo add inventory
            end

            carrier.train.manual_mode = false

            task:deploying_cursor_next()
        end

    elseif task:is_state_deploying() and result_train_length == target_train_length then
        local trains_in_block = false
        for _, rail in ipairs(depot_station_signal.get_connected_rails()) do
            if rail.trains_in_block > 0 then
                trains_in_block = true
                break
            end
        end

        if not trains_in_block then
            task:deployed()
            task:delete()
            private.register_train_for_template(main_locomotive.train, train_template)
        end
    end

    persistence_storage.trains_tasks.add(task)
end

---@param data NthTickEventData
function deploy.deploy_trains(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(forming.get_forming_tasks_contexts()) do
        deploy.deploy_trains_for_context(context, data)
    end

    if persistence_storage.trains_tasks.count_forming_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.train_deploy, nil)
    end
end

---@param context scripts.lib.domain.Context
function deploy.is_deploy_slot_empty(context)
    return persistence_storage.trains_tasks.count_deploying_tasks(context) == 0
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function deploy.deploy_task(context, task, tick)
    if not task:is_state_deploying() and not task:is_state_formed() then
        return
    end

    if task:is_state_formed() and not deploy.is_deploy_slot_empty(context) then
        return
    end

    deploy.try_deploy_train(context, task, tick)
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function deploy.deploy_trains_for_context(context, data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_forming_tasks_ready_for_deploy(context)

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(tasks) do
        deploy.deploy_task(context, task, tick)
    end
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param train_task scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
function private.raise_task_changed_event(train_task)
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

---@param task scripts.lib.domain.entity.task.TrainFormingTask
---@param tick uint
function private.process_forming_task(task, tick)
    local multiplier = private.get_depot_multiplier()

    if not task:is_state_created() and not task:is_state_forming() then
        return false
    end

    if task:is_state_created() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)

        task:start_forming_train(tick, multiplier, train_template)
    end

    if task:is_forming_time_left(tick) then
        task:state_formed()
    end

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    return true
end

---@param data NthTickEventData
function private.process_tasks(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_forming_tasks()

    -- todo not process task if depot not exists

    for _, task in pairs(tasks) do
        private.process_forming_task(task, tick)

        if task:is_state_formed() then
            script.on_nth_tick(atd.defines.on_nth_tick.train_deploy, deploy.deploy_trains)
        end
    end

    if persistence_storage.trains_tasks.total_count_forming_tasks() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.tasks_processor, nil)
    end
end

function private.on_ntd_register_queue_processor()
    script.on_nth_tick(atd.defines.on_nth_tick.tasks_processor, private.process_tasks)
end

function private.find_contexts_with_depot()
    return flib_table.filter(
        persistence_storage.find_contexts_from_train_templates(),
        function(c)
            return persistence_storage.is_depot_exists_at(c)
        end,
        true
    )
end

---@param data NthTickEventData
function private.balance_trains_count(data)
    local contexts_with_depot = private.find_contexts_with_depot()

    for _, c in ipairs(contexts_with_depot) do
        private.balance_trains_count_for_context(c, data)
    end
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function private.balance_trains_count_for_context(context, data)
    local train_templates = persistence_storage.find_enabled_train_templates(context)

    ---@param train_template scripts.lib.domain.entity.template.TrainTemplate
    for _, train_template in pairs(train_templates) do
        local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
        local forming_train_tasks_count = persistence_storage.trains_tasks.count_forming_tasks(context, train_template.id)
        local disband_train_tasks_count = persistence_storage.trains_tasks.count_disband_tasks(context, train_template.id)
        local potential_count = #trains + forming_train_tasks_count - disband_train_tasks_count
        local diff = train_template.trains_quantity - potential_count

        if diff > 0 then
            for _ = 1, diff do
                if not disband.try_discard_disbanding_train_task_for_template(train_template) then
                    break
                end

                diff = diff - 1
            end

            if diff > 0 then
                forming.try_add_forming_train_task_for_template(train_template)
            end
        elseif diff < 0 then
            local delete_count = diff * -1

            for _ = 1, delete_count do
                if not forming.try_discard_forming_train_task_for_template(train_template) then
                    break
                end

                delete_count = delete_count - 1
            end

            if delete_count > 0 then
                disband.try_add_disband_train_task_for_template(train_template)
            end
        end
    end

    local total_forming_tasks_count = persistence_storage.trains_tasks.count_forming_tasks(context)
    local total_disband_tasks_count = persistence_storage.trains_tasks.count_disband_tasks(context)

    if total_forming_tasks_count + total_disband_tasks_count > 0 then
        private.on_ntd_register_queue_processor()
    end
end

function private.register_event_handlers()
    local handlers = {}

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "depot")
    end
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    train_service.register_trains()

    private.register_event_handlers()
end

function public.load()
    private.register_event_handlers()
end

---@param train_template_id uint
function public.enable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template.enabled = true

    train_template = persistence_storage.add_train_template(train_template)

    public.trains_balancer_start()

    return train_template
end

function public.disable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    train_template.enabled = false

    train_template = persistence_storage.add_train_template(train_template)

    if persistence_storage.count_active_trains_templates() == 0 then
        public.trains_balancer_pause()
    end

    return train_template
end

---@param train_template_id uint
---@param count int
function public.change_trains_quantity(train_template_id, count)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template:change_trains_quantity(count)
    persistence_storage.add_train_template(train_template)

    if train_template.enabled then
        public.trains_balancer_start()
    end

    return train_template
end

function public.trains_balancer_start()
    script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, private.balance_trains_count)

    logger.debug("Start trains balancer", {}, "depot")
end

---@param schedule TrainSchedule
function public.is_valid_schedule(schedule)
    local is_path_readable = false

    return is_path_readable
end

function public.trains_balancer_pause()
    script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, nil)

    logger.debug("Pause trains balancer", {}, "depot")
end

return public