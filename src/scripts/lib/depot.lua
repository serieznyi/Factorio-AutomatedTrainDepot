local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local trains_balancer = require("scripts.lib.train.trains_balancer")
local train_constructor = require("scripts.lib.train.train_constructor")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")
local logger = require("scripts.lib.logger")
local util_table = require("scripts.util.table")

---@alias TrainStat {train: LuaTrain, has_cargo: bool, drive_to_last_station: bool}[]

local Depot = {}

function Depot.init()
    Depot._register_event_handlers()
end

function Depot.load()
    Depot._register_event_handlers()
end

---@param schedule TrainSchedule
function Depot.is_valid_schedule(schedule)
    local is_path_readable = false

    -- todo add realisation

    return is_path_readable
end

---@param context scripts.lib.domain.Context
function Depot.is_depot_building_exists(context)
    return remote.call("atd", "depot_building_exists", context)
end

---@param task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function Depot._try_remove_completed_task(task, tick)
    if not task:is_state_completed() then
        return
    end

    local completed_since = tick - task.completed_at

    if completed_since > atd.defines.time_in_ticks.seconds_2 then
        task:delete()

        persistence_storage.trains_tasks.add(task)

        Depot._raise_task_changed_event(task)
    end
end

---@param train_task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function Depot._raise_task_changed_event(train_task)
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

function Depot._get_depot_multiplier()
    return 1.0 -- todo depended from technologies
end

---@param train scripts.lib.domain.entity.Train
function Depot._is_train_marked_to_disband(train)
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
function Depot._is_train_has_cargo(train)
    return false -- todo add logic
end

---@param train scripts.lib.domain.entity.Train
---@return bool
function Depot._is_train_drive_to_last_station(train)
    local schedule = train.lua_train.schedule

    if schedule == nil then
        return false
    end

    return #schedule.records == schedule.current
end

---@param stat TrainStat
---@return uint
function Depot._build_train_disband_priority(stat)
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
function Depot._try_bind_train_with_disband_task(task)
    local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
    ---@type {train: LuaTrain, has_cargo: bool, drive_to_last_station: bool, trains_stat: uint}[]
    local trains_stat = {}

    -- collect trains stat
    for _, train in ipairs(trains) do
        if not Depot._is_train_marked_to_disband(train) then
            local train_stat = {}

            train_stat.train = train
            train_stat.has_cargo = Depot._is_train_has_cargo(train)
            train_stat.drive_to_last_station = Depot._is_train_drive_to_last_station(train)
            train_stat.priority = Depot._build_train_disband_priority(train_stat)

            table.insert(trains_stat, train_stat)
        end
    end

    table.sort(trains_stat, function (left, right)
        return left.priority > right.priority
    end)

    if #trains_stat ~= 0 then
        local train = trains_stat[1]
        task:bind_with_train(train.train.id)
    end

    return task.train_id ~= nil
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function Depot._pass_train_to_depot(task)
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
function Depot._process_disbanding_task(task, tick)
    local changed = false

    if task:is_state_created() then
        if task.train_id ~= nil then -- Disband uncontrolled train
            Depot._pass_train_to_depot(task)

            task:state_wait_train()
        elseif task.train_id == nil then -- Disband controlled train
            task:state_try_choose_train()
        end

        changed = true
    elseif task:is_state_try_choose_train() then
        if Depot._try_bind_train_with_disband_task(task) then
            Depot._pass_train_to_depot(task)

            task:state_wait_train()

            changed = true
        end
    elseif task:is_state_take_apart() then
        local train = persistence_storage.find_train(task.train_id)

        if #task.carriages_ids == 0 then
            local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
            local multiplier = Depot._get_depot_multiplier()

            train:delete()
            persistence_storage.add_train(train)

            task:state_disband(tick, multiplier, train_template);
            changed = true
        else
            if train ~= nil then
                local lua_train = train.lua_train

                if lua_train.valid then
                    local carriages_quantity = #lua_train.carriages

                    --if task.take_apart_cursor == 2 then
                        --local context = Context.from_model(task)
                        --local surface = game.surfaces[context.surface_name]
                        --local carriage_id = task.carriages_ids[1]
                        --local depot_locomotive_entity_data = {
                        --    name = "locomotive",
                        --    position = train_position,
                        --    direction = carrier_direction,
                        --    force = game.forces[context.force_name],
                        --};
                        --if surface.can_place_entity(depot_locomotive_entity_data) then
                        --    ---@type LuaEntity
                        --    local depot_train = surface.create_entity(depot_locomotive_entity_data)
                        --    depot_train.get_inventory(defines.inventory.fuel).insert({name = "coal", count = 50})
                        --
                        --    task.take_apart_cursor = 0
                        --    table.insert(task.carriages_ids, 1, depot_train.unit_number)
                        --    persistence_storage.trains_tasks.add(task)
                        --    -- todo drive to depot station
                        --    break
                        --end
                    --else
                        local id = task.carriages_ids[1]

                        for _, carriage in ipairs(lua_train.carriages) do
                            if carriage.unit_number == id then
                                task:take_apart_cursor_next()
                                persistence_storage.trains_tasks.add(task)
                                carriage.destroy()
                                break
                            end
                        end
                    --end
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

        Depot._raise_task_changed_event(task)
    end

end

---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function Depot._process_form_task(task, tick)
    local multiplier = Depot._get_depot_multiplier()

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

    Depot._raise_task_changed_event(task)

    return true
end

---@param data NthTickEventData
function Depot._train_manipulations(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        if task.type == TrainFormTask.type then
            Depot._process_form_task(task, tick)
        elseif task.type == TrainDisbandTask.type then
            Depot._process_disbanding_task(task, tick)
        end

        Depot._try_remove_completed_task(task, data.tick)
    end
end

function Depot._handle_trains_balancer_run(e)
    trains_balancer.balance_trains_quantity()
end

function Depot._handle_train_manipulations_check_activity(e)
    Depot._train_manipulations_check_activity()
end

function Depot._handle_trains_constructor_check_activity(e)
    Depot._trains_constructor_check_activity()
end

---@param e scripts.lib.event.Event
function Depot._handle_trains_deconstruct_check_activity(e)
    local context = Context.from_train(e.original_event.train)

    if not Depot.is_depot_building_exists(context) then
        return false
    end

    Depot._trains_deconstruct_check_activity(context)

    return true
end

function Depot._trains_constructor_check_activity()
    if persistence_storage.trains_tasks.count_form_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, train_constructor.construct)
    end
end

---@param new_train LuaTrain
---@param old_train_id_1 uint|nil
function Depot._try_re_register_train_in_disband_task(new_train, old_train_id_1)
    if old_train_id_1 == nil then
        return
    end

    local task = persistence_storage.trains_tasks.find_disbanding_task_by_train(old_train_id_1)

    if task == nil then
        return
    end

    if task.train_id == old_train_id_1 then
        task:bind_with_train(new_train.id)
        persistence_storage.trains_tasks.add(task)

        Depot._raise_task_changed_event(task)
    end
end

---@param e scripts.lib.event.Event
function Depot._handle_train_created(e)
    local lua_event = e.original_event

    local new_train = lua_event.train
    local old_train_id_1 = lua_event.old_train_id_1

    Depot._try_re_register_train_in_disband_task(new_train, old_train_id_1)
end

---@param context scripts.lib.domain.Context
function Depot._trains_deconstruct_check_activity(context)
    ---@type LuaEntity
    local depot_input_station = remote.call("atd", "depot_get_input_station", context)

    ---@type LuaTrain
    local stopped_train = depot_input_station.get_stopped_train()

    if stopped_train == nil then
        return
    end

    local task = persistence_storage.trains_tasks.find_disbanding_task_by_train(stopped_train.id)

    assert(task, "unknown train on depot stop")

    if task:is_state_wait_train() then
        task:state_take_apart(util_table.map(stopped_train.carriages, function(v) return v.unit_number end))
        persistence_storage.trains_tasks.add(task)
        -- todo move raise in repo ?
        Depot._raise_task_changed_event(task)
    end
end

function Depot._train_manipulations_check_activity()
    local count_tasks = persistence_storage.trains_tasks.total_count_tasks()

    if count_tasks == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, Depot._train_manipulations)
    end
end

function Depot._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = function(e) return Depot._handle_trains_balancer_run(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_changed),
            handler = function(e) return Depot._handle_trains_balancer_run(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return Depot._handle_trains_constructor_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return Depot._handle_train_manipulations_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(defines.events.on_train_changed_state),
            handler = function(e) return Depot._handle_trains_deconstruct_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(defines.events.on_train_created),
            handler = function(e) return Depot._handle_train_created(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "depot")
    end
end

return Depot