local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_table = require("scripts.util.table")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local logger = require("scripts.lib.logger")

local TrainsDeconstructor = {}

function TrainsDeconstructor.init()
    TrainsDeconstructor._register_event_handlers()
end

function TrainsDeconstructor.load()
    TrainsDeconstructor._register_event_handlers()
end

---@param context scripts.lib.domain.Context
function TrainsDeconstructor._trains_deconstruct_check_activity(context)
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

---@param e scripts.lib.event.Event
function TrainsDeconstructor._handle_train_created(e)
    local lua_event = e.original_event

    local new_train = lua_event.train
    local old_train_id_1 = lua_event.old_train_id_1
    local old_train_id_2 = lua_event.old_train_id_2

    TrainsDeconstructor._try_re_register_train_in_disband_task(new_train, old_train_id_1, old_train_id_2)
end

---@param e scripts.lib.event.Event
function TrainsDeconstructor._handle_trains_deconstruct_check_activity(e)
    local context = Context.from_train(e.original_event.train)

    if not TrainsDeconstructor._is_depot_building_exists(context) then
        return false
    end

    TrainsDeconstructor._trains_deconstruct_check_activity(context)

    return true
end

function TrainsDeconstructor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(defines.events.on_train_changed_state),
            handler = TrainsDeconstructor._handle_trains_deconstruct_check_activity,
        },
        {
            match = EventDispatcher.match_event(defines.events.on_train_created),
            handler = TrainsDeconstructor._handle_train_created,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "TrainsDeconstructor")
    end
end

return TrainsDeconstructor