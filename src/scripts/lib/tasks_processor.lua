local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local trains_balancer = require("scripts.lib.train.trains_balancer")
local train_constructor = require("scripts.lib.train.form.train_constructor")
local train_deconstructor = require("scripts.lib.train.disband.train_deconstructor")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")
local util_table = require("scripts.util.table")
local logger = require("scripts.lib.logger")

---@alias TrainStat {train: LuaTrain, has_cargo: bool, drive_to_last_station: bool}[]

local TasksProcessor = {}

function TasksProcessor.init()
    TasksProcessor._register_event_handlers()

    train_constructor.init()
    train_deconstructor.init()
end

function TasksProcessor.load()
    TasksProcessor._register_event_handlers()

    train_constructor.load()
    train_deconstructor.load()
end

---@param schedule TrainSchedule
function TasksProcessor.is_valid_schedule(schedule)
    local is_path_readable = false

    -- todo add realisation

    return is_path_readable
end

---@param task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function TasksProcessor._try_remove_completed_task(task, tick)
    if not task:is_state_completed() then
        return
    end

    local completed_since = tick - task.completed_at

    if completed_since > atd.defines.time_in_ticks.seconds_2 then
        task:delete()

        persistence_storage.trains_tasks.add(task)
    end
end

function TasksProcessor._get_depot_multiplier()
    return 1.0 -- todo depended from technologies
end

---@param train scripts.lib.domain.entity.Train
function TasksProcessor._is_train_marked_to_disband(train)
    local context = Context.from_model(train)
    local tasks = persistence_storage.trains_tasks.find_disbanding_tasks(context, train.train_template_id)

    for _, task in ipairs(tasks) do
        if task.train_id == train.id then
            return true
        end
    end

    return false
end

---@param train scripts.lib.domain.entity.Train
---@return bool
function TasksProcessor._is_train_has_cargo(train)
    return false -- todo add logic
end

---@param train scripts.lib.domain.entity.Train
---@return bool
function TasksProcessor._is_train_drive_to_last_station(train)
    local schedule = train.lua_train.schedule

    if schedule == nil then
        return false
    end

    return #schedule.records == schedule.current
end

---@param stat TrainStat
---@return uint
function TasksProcessor._build_train_disband_priority(stat)
    local priority = 1

    if stat.drive_to_last_station then
        priority = priority + 1
    end

    if not stat.has_cargo then
        priority = priority + 1
    end

    return priority
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function TasksProcessor._try_bind_train_with_disband_task(task)
    local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
    ---@type {train: LuaTrain, has_cargo: bool, drive_to_last_station: bool, trains_stat: uint}[]
    local trains_stat = {}

    -- collect trains stat
    for _, train in ipairs(trains) do
        if not TasksProcessor._is_train_marked_to_disband(train) then
            local train_stat = {}

            train_stat.train = train
            train_stat.has_cargo = TasksProcessor._is_train_has_cargo(train)
            train_stat.drive_to_last_station = TasksProcessor._is_train_drive_to_last_station(train)
            train_stat.priority = TasksProcessor._build_train_disband_priority(train_stat)

            table.insert(trains_stat, train_stat)
        end
    end

    table.sort(trains_stat, function (left, right)
        return left.priority > right.priority
    end)

    if #trains_stat ~= 0 then
        local train_stat = trains_stat[1]
        task:bind_with_train(train_stat.train.lua_train)
    end

    return task.train_id ~= nil
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function TasksProcessor._pass_train_to_depot(task)
    local train = persistence_storage.find_train(task.train_id)
    local context = Context.from_model(task)

    assert(train, "train is nil")

    local lua_train = train.lua_train

    -- todo add path to clean station ?

    ---@type LuaEntity
    local depot_input_station = remote.call("atd", "depot_get_input_station", context)

    local new_train_schedule = util_table.deep_copy(lua_train.schedule)

    table.insert(new_train_schedule.records, {
        --rail = depot_input_station.connected_rail,
        station = depot_input_station.backer_name,
        wait_conditions = {
            {
                type = "time",
                ticks = atd.defines.time_in_ticks.seconds_30,
                compare_type = "and",
            }
        }
    })

    lua_train.schedule = new_train_schedule
end

---@param first_carriage LuaTrain
---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function TasksProcessor._add_depot_train(first_carriage, task)
    local context = Context.from_model(task)
    ---@type LuaEntity
    local depot_input_station = remote.call("atd", "depot_get_input_station", context)
    local surface = game.surfaces[context.surface_name]
    local carriage_id = task.carriages_ids[1]
    ---@type LuaEntity
    local first_carrier

    for _, carriage in ipairs(first_carriage.carriages) do
        if carriage.unit_number == carriage_id then
            first_carrier = carriage
        end
    end

    assert(first_carrier)

    local first_carrier_position = first_carrier.position
    local direction = depot_input_station.direction
    local depot_locomotive_entity_data = {
        name = "locomotive",
        position = {
            first_carrier_position.x + atd.defines.rotate_relative_position[direction](0, -7),
            first_carrier_position.y
        },
        direction = direction,
        force = game.forces[context.force_name],
    };

    if surface.can_place_entity(depot_locomotive_entity_data) then
        task.take_apart_cursor = 0 -- reset cursor
        persistence_storage.trains_tasks.add(task, false)

        ---@type LuaEntity
        local depot_train = surface.create_entity(depot_locomotive_entity_data)
        -- todo use any fuel with max fuel value. move in func
        depot_train.get_inventory(defines.inventory.fuel).insert({name = "nuclear-fuel", count = 1})
    end
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function TasksProcessor._process_disbanding_task(task, tick)
    local changed = false

    if task:is_state_created() then
        if task.train_id ~= nil then -- Disband uncontrolled train
            TasksProcessor._pass_train_to_depot(task)

            task:state_wait_train()
        elseif task.train_id == nil then -- Disband controlled train
            task:state_try_choose_train()
        end

        changed = true
    elseif task:is_state_try_choose_train() then
        if TasksProcessor._try_bind_train_with_disband_task(task) then
            TasksProcessor._pass_train_to_depot(task)

            task:state_wait_train()

            changed = true
        end
    elseif task:is_state_take_apart() then
        local train = persistence_storage.find_train(task.train_id)
        local train_valid = train ~= nil and train.lua_train.valid

        if not train_valid then
            return
        end

        if train.lua_train.riding_state.acceleration ~= defines.riding.acceleration.nothing then
            return
        end

        if task.take_apart_cursor == 0 and train.lua_train.manual_mode == true then

            train.lua_train.manual_mode = false
        elseif #task.carriages_ids == 0 then
            local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
            local multiplier = TasksProcessor._get_depot_multiplier()

            task:state_disband(tick, multiplier, train_template);
            changed = true
        elseif task.take_apart_cursor == 2 then
            TasksProcessor._add_depot_train(train.lua_train, task)
        else
            local id = task.carriages_ids[1]

            for _, carriage in ipairs(train.lua_train.carriages) do
                if carriage.unit_number == id then
                    task:take_apart_cursor_next()

                    -- save task in place and not raise event because train_id will updated in task later
                    persistence_storage.trains_tasks.add(task, false)
                    carriage.destroy()
                    break
                end
            end
        end
    elseif task:is_state_disband() then
        if task:is_disband_time_left(tick) then
            task:state_completed(tick)
            changed = true
        end
    end

    if changed then
        persistence_storage.trains_tasks.add(task)
    end

end

---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function TasksProcessor._process_form_task(task, tick)
    local multiplier = TasksProcessor._get_depot_multiplier()

    if not task:is_state_created() and not task:is_state_form() then
        return false
    end

    if task:is_state_created() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)

        task:state_form(tick, multiplier, train_template)
    end

    if task:is_form_time_left(tick) then
        task:state_formed()
    end

    persistence_storage.trains_tasks.add(task)

    return true
end

---@param data NthTickEventData
function TasksProcessor._train_manipulations(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        if task.type == TrainFormTask.type then
            TasksProcessor._process_form_task(task, tick)
        elseif task.type == TrainDisbandTask.type then
            TasksProcessor._process_disbanding_task(task, tick)
        end

        TasksProcessor._try_remove_completed_task(task, data.tick)
    end
end

function TasksProcessor._handle_trains_balancer_run(e)
    trains_balancer.balance_trains_quantity()
end

function TasksProcessor._handle_train_manipulations_check_activity(e)
    local count_tasks = persistence_storage.trains_tasks.total_count_tasks()

    if count_tasks == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, TasksProcessor._train_manipulations)
    end
end

function TasksProcessor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = TasksProcessor._handle_trains_balancer_run,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_changed),
            handler = TasksProcessor._handle_trains_balancer_run,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = TasksProcessor._handle_train_manipulations_check_activity,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "depot")
    end
end

return TasksProcessor