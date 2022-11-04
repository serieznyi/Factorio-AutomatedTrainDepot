local flib_misc = require("__flib__.misc")

local depot_storage_service = require("scripts.lib.depot_storage_service")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_table = require("scripts.util.table")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local logger = require("scripts.lib.logger")
local notifier = require("scripts.lib.notifier")
local alert_service = require("scripts.lib.alert_service")

local TrainsDeconstructor = {}

function TrainsDeconstructor.init()
    TrainsDeconstructor._register_event_handlers()
end

function TrainsDeconstructor.load()
    TrainsDeconstructor._register_event_handlers()
end

---@param context scripts.lib.domain.Context
function TrainsDeconstructor._start_train_take_apart(context)
    ---@type LuaEntity
    local depot_input_station = remote.call("atd", "depot_get_input_station", context)

    ---@type LuaTrain
    local stopped_train = depot_input_station.get_stopped_train()
    local stop_rail = depot_input_station.connected_rail

    if stopped_train == nil then
        return
    end

    local task = persistence_storage.trains_tasks.find_disbanding_task_by_train(stopped_train.id)

    assert(task, "unknown train on depot stop")

    if task:is_state_wait_train() then
        local carrier_on_stop = stop_rail.surface.find_entities_filtered{
            position = stop_rail.position,
            radius = 4.0,
            type = {"locomotive", "artillery-wagon", "cargo-wagon", "fluid-wagon"},
            limit = 1
        }

        if #carrier_on_stop == 0 then
            return
        end

        local front_locomotive_id = carrier_on_stop[1].unit_number

        task:state_take_apart(stopped_train, front_locomotive_id)
        persistence_storage.trains_tasks.add(task)

        return true
    end
end

---@param context scripts.lib.domain.Context
function TrainsDeconstructor._is_depot_building_exists(context)
    return remote.call("atd", "depot_building_exists", context)
end

---@param new_train LuaTrain
---@param old_train_id_1 uint|nil
function TrainsDeconstructor._try_re_register_train_in_disband_task(new_train, old_train_id_1, old_train_id_2)
    local change_exists_train = old_train_id_1 ~= nil and old_train_id_2 == nil
    local merge_exists_train = old_train_id_1 ~= nil and old_train_id_2 ~= nil

    if not change_exists_train and not merge_exists_train then
        return
    end

    local min = change_exists_train and old_train_id_1 or math.min(old_train_id_1, old_train_id_2)

    local task = persistence_storage.trains_tasks.find_disbanding_task_by_train(min)

    if task == nil then
        return
    end

    local changed = false

    for _, v in ipairs(new_train.carriages) do
        -- todo hide in task model
        if util_table.find(task.carriages_ids, v.unit_number) == nil then
            table.insert(task.carriages_ids, 1, v.unit_number)
            changed = true
            break
        end
    end

    if task.train_id == old_train_id_1 or task.train_id == old_train_id_2 then
        task.train_id = new_train.id
        changed = true
    end

    if changed then
        persistence_storage.trains_tasks.add(task, false)
    end
end

-- todo duplicity
function TrainsDeconstructor._get_contexts_from_tasks()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        table.insert(contexts, Context.from_model(task))
    end

    return contexts
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function TrainsDeconstructor._try_deconstruct_train(context, task, tick)
    if not task:is_state_take_apart() then
        return
    end

    local train = persistence_storage.find_train(task.train_id)
    local train_valid = train ~= nil and train.lua_train.valid

    if not train_valid then
        return
    end

    if not depot_storage_service.can_store_train(context, train.lua_train) then
        -- todo do not repeat every tick
        notifier.error(context:force(), {"depot-notifications.atd-no-free-space-in-depot-storage"})
        alert_service.add(context, atd.defines.alert_type.depot_storage_full)
        train.lua_train.manual_mode = true
        return
    else
        alert_service.remove(context, atd.defines.alert_type.depot_storage_full)
    end

    if task.take_apart_cursor == 2 then
        TrainsDeconstructor._add_depot_locomotive(train.lua_train, task)
        return
    end

    local id = task.carriages_ids[1]

    for _, carriage in ipairs(train.lua_train.carriages) do
        if carriage.unit_number == id then
            local depot_locomotive = carriage.name == atd.defines.prototypes.entity.depot_locomotive.name

            if depot_locomotive then
                ---@type LuaEntity
                local depot_input_station = remote.call("atd", "depot_get_input_station", context)
                local prev_stop_rail = depot_input_station.connected_rail.get_connected_rail{
                    rail_direction = defines.rail_direction.back,
                    rail_connection_direction = defines.rail_connection_direction.straight
                }
                local distance = flib_misc.get_distance(prev_stop_rail.position, carriage.position)

                TrainsDeconstructor._ride_train_to(carriage, prev_stop_rail.position)

                local in_place = distance <= 0.5 and distance >= 0

                if not in_place then
                    return
                end
            end

            task:take_apart_cursor_next()

            -- save task in place and not raise event because train_id will updated in task later
            persistence_storage.trains_tasks.add(task, false)

            if depot_locomotive then
                carriage.get_driver().destroy()
            end

            TrainsDeconstructor._destroy_carriage(carriage)
            break
        end
    end
end

---@param carriage LuaEntity
function TrainsDeconstructor._destroy_carriage(carriage)
    if carriage.name ~= atd.defines.prototypes.entity.depot_locomotive.name then
        depot_storage_service.put_carriage(Context.from_entity(carriage), carriage)
    end

    carriage.destroy{raise_destroy = true}
end

-- todo first_carriage used not correct
---@param first_carriage LuaTrain
---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function TrainsDeconstructor._add_depot_locomotive(first_carriage, task)
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

    if first_carrier.name == atd.defines.prototypes.entity.depot_locomotive then
        return
    end

    local first_carrier_position = first_carrier.position
    local direction = depot_input_station.direction
    local depot_locomotive_entity_data = {
        name = atd.defines.prototypes.entity.depot_locomotive.name,
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
        local depot_locomotive = surface.create_entity(depot_locomotive_entity_data)
        -- todo use any fuel with max fuel value. move in func
        depot_locomotive.get_inventory(defines.inventory.fuel).insert({ name = "rocket-fuel", count = 1})

        TrainsDeconstructor._add_depot_driver(depot_locomotive)

        depot_locomotive.train.schedule = nil
    end
end

---@param depot_locomotive LuaEntity
function TrainsDeconstructor._ride_train_to(depot_locomotive, destination)
    ---@type LuaTrain
    local train = depot_locomotive.train
    local speed = math.abs(train.speed)
    local train_driver = depot_locomotive.get_driver()
    local min_speed = 0.05

    -- control train speed
    if speed < min_speed then
        train_driver.riding_state = {
            --acceleration = defines.riding.acceleration.accelerating, -- todo use correct direction
            acceleration = defines.riding.acceleration.reversing, -- todo use correct direction
            direction = defines.riding.direction.straight,
        }
    elseif speed >= min_speed then
        train_driver.riding_state = {
            acceleration = defines.riding.acceleration.nothing,
            direction = defines.riding.direction.straight,
        }
    end
end

---@param locomotive LuaEntity
function TrainsDeconstructor._add_depot_driver(locomotive)
    local train_driver = locomotive.surface.create_entity({
        name = atd.defines.prototypes.entity.depot_driver.name,
        position = locomotive.position,
        force = locomotive.force,
    })

    locomotive.set_driver(train_driver)
end

---@param context scripts.lib.domain.Context
---@param tick uint
function TrainsDeconstructor._deconstruct_trains_for_context(context, tick)
    if not persistence_storage.is_depot_exists_at(context) then
        -- todo remove formed tasks if depot was destroyed and reset all finished tasks
        return
    end

    local tasks = persistence_storage.trains_tasks.find_disband_tasks_ready_for_take_apart(context)

    ---@param task scripts.lib.domain.entity.task.TrainDisbandTask
    for _, task in pairs(tasks) do
        TrainsDeconstructor._try_deconstruct_train(context, task, tick)
    end
end

---@param data NthTickEventData
function TrainsDeconstructor._deconstruct(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(TrainsDeconstructor._get_contexts_from_tasks()) do
        TrainsDeconstructor._deconstruct_trains_for_context(context, data.tick)
    end
end

function TrainsDeconstructor._trains_deconstructor_check_activity()
    if persistence_storage.trains_tasks.find_disband_tasks_ready_for_take_apart() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deconstruct, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deconstruct, TrainsDeconstructor._deconstruct)
    end
end

---@param event EventData
function TrainsDeconstructor._handle_trains_deconstructor_check_activity(event)
    TrainsDeconstructor._trains_deconstructor_check_activity()
end

---@param e scripts.lib.event.Event
function TrainsDeconstructor._handle_train_created(e)
    local lua_event = e.original_event

    local new_train = lua_event.train
    local old_train_id_1 = lua_event.old_train_id_1
    local old_train_id_2 = lua_event.old_train_id_2

    TrainsDeconstructor._try_re_register_train_in_disband_task(new_train, old_train_id_1, old_train_id_2)
end

---@param e scripts.lib.event.Event
function TrainsDeconstructor._handle_start_train_take_apart(e)
    local context = Context.from_train(e.original_event.train)

    if not TrainsDeconstructor._is_depot_building_exists(context) then
        return false
    end

    if TrainsDeconstructor._start_train_take_apart(context) then
        TrainsDeconstructor._trains_deconstructor_check_activity()
    end

    return true
end

function TrainsDeconstructor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(defines.events.on_train_changed_state),
            handler = TrainsDeconstructor._handle_start_train_take_apart,
        },
        {
            match = EventDispatcher.match_event(defines.events.on_train_created),
            handler = TrainsDeconstructor._handle_train_created,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = TrainsDeconstructor._handle_trains_deconstructor_check_activity,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "TrainsDeconstructor")
    end
end

return TrainsDeconstructor