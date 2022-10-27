local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_table = require("scripts.util.table")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")

local TrainsDeconstructor = {}

function TrainsDeconstructor.init()
    TrainsDeconstructor._register_event_handlers()
end

function TrainsDeconstructor.load()
    TrainsDeconstructor._register_event_handlers()
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

---@param context scripts.lib.domain.Context
function TrainsDeconstructor._trains_deconstruct_check_activity(context)
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
        TrainsDeconstructor._raise_task_changed_event(task)
    end
end

-- todo duplicity
---@param train_task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function TrainsDeconstructor._raise_task_changed_event(train_task)
    ---@type LuaForce
    local force = game.forces[train_task.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
                atd.defines.events.on_core_train_task_changed,
                { train_task_id = train_task.id, player_index = player.index }
        )
    end

end

---@param context scripts.lib.domain.Context
function TrainsDeconstructor._is_depot_building_exists(context)
    return remote.call("atd", "depot_building_exists", context)
end

---@param e scripts.lib.event.Event
function TrainsDeconstructor._handle_train_created(e)
    local lua_event = e.original_event

    local new_train = lua_event.train
    local old_train_id_1 = lua_event.old_train_id_1

    TrainsDeconstructor._try_re_register_train_in_disband_task(new_train, old_train_id_1)
end

---@param new_train LuaTrain
---@param old_train_id_1 uint|nil
function TrainsDeconstructor._try_re_register_train_in_disband_task(new_train, old_train_id_1)
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

        TrainsDeconstructor._raise_task_changed_event(task)
    end
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