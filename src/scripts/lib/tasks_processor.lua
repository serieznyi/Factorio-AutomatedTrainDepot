local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local trains_balancer = require("scripts.lib.train.trains_balancer")
local train_constructor = require("scripts.lib.train.form.train_constructor")
local train_deconstructor = require("scripts.lib.train.disband.train_deconstructor")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")
local util_table = require("scripts.util.table")
local depot_storage_service = require("scripts.lib.depot_storage_service")
local alert_service = require("scripts.lib.alert_service")
local logger = require("scripts.lib.logger")

---@alias TrainStat {train: LuaTrain, has_cargo: bool, drive_to_last_station: bool}[]

local TasksProcessor = {}

function TasksProcessor.init()
    TasksProcessor._register_event_handlers()

    train_constructor.init()
    train_deconstructor.init()

    script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, TasksProcessor._train_manipulations)
end

function TasksProcessor.load()
    TasksProcessor._register_event_handlers()

    train_constructor.load()
    train_deconstructor.load()

    script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, TasksProcessor._train_manipulations)
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
    local trains = persistence_storage.find_controlled_trains(context, train_template.id)
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
    elseif task:is_state_take_apart() and #task.carriages_ids == 0 then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
        local multiplier = TasksProcessor._get_depot_multiplier()

        task:state_disband(tick, multiplier, train_template);
        changed = true
    elseif task:is_state_disband() then
        local context = Context.from_model(task)
        local can_store_train_in_storage = depot_storage_service.can_store(context, task.train_items)

        if not can_store_train_in_storage then
            alert_service.add(context, atd.defines.alert_type.depot_storage_full)
        else
            alert_service.remove(context, atd.defines.alert_type.depot_storage_full)
        end

        if task:is_disband_time_left(tick) and can_store_train_in_storage then
            depot_storage_service.put_items(context, task.train_items)
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

---@param tick uint
function TasksProcessor._train_manipulations(tick)
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        if task.type == TrainFormTask.type then
            TasksProcessor._process_form_task(task, tick)
        elseif task.type == TrainDisbandTask.type then
            TasksProcessor._process_disbanding_task(task, tick)
        end

        TasksProcessor._try_remove_completed_task(task, tick)
    end
end

function TasksProcessor._ndt_handle_trains_balancer(e)
    trains_balancer.balance_trains_quantity()
end

function TasksProcessor._handle_trains_balancer(e)
    if trains_balancer.is_trains_quantity_synchronized() then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_balancer, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_balancer, TasksProcessor._ndt_handle_trains_balancer)
    end
end

---@param data NthTickEventData
function TasksProcessor._ndt_handle_train_manipulations(data)
    TasksProcessor._train_manipulations(data.tick)
end

function TasksProcessor._handle_train_manipulations_check_activity(e)
    local count_tasks = persistence_storage.trains_tasks.total_count_tasks()

    if count_tasks == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, TasksProcessor._ndt_handle_train_manipulations)
    end
end

function TasksProcessor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_events(
                atd.defines.events.on_core_train_template_changed,
                atd.defines.events.on_core_train_changed
            ),
            handler = TasksProcessor._handle_trains_balancer,
        },
        {
            match = EventDispatcher.match_events(atd.defines.events.on_core_train_task_changed),
            handler = TasksProcessor._handle_train_manipulations_check_activity,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "TasksProcessor")
    end
end

return TasksProcessor