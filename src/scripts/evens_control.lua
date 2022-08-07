local flib_table = require("__flib__.table")

local depot_building = require("scripts.depot.depot_building")
local gui_manager = require("scripts.gui.manager")
local console = require("scripts.console")
local Event = require("scripts.lib.event.Event")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local train_service = require("scripts.lib.train_service")

---@param entity LuaEntity
local function is_rolling_stock(entity)
    return entity.type == "locomotive" or entity.type == "cargo-wagon"
end

local events_control = {}

---@param event EventData
function events_control.reload_settings(event)
    console.load(event.player_index)
end

---@param event EventData
function events_control.entity_build(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == "entity-ghost" and entity.ghost_name == mod.defines.prototypes.entity.depot_building.name then
        depot_building.build_ghost(entity)
    elseif entity.name == mod.defines.prototypes.entity.depot_building.name then
        local player = event.player_index ~= nil and game.get_player(event.player_index) or nil

        depot_building.build(entity, player)
    end
end

---@param event EventData
function events_control.entity_rotated(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == mod.defines.prototypes.entity.depot_building.name then
        depot_building.revert_rotation(entity, event.previous_direction)
    end
end

---@param event EventData
function events_control.entity_dismantled(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == mod.defines.prototypes.entity.depot_building.name then
        depot_building.destroy(entity)
    elseif is_rolling_stock(entity) then
        local left_carriages = flib_table.filter(entity.train.carriages, function(e)
            return e.unit_number ~= entity.unit_number
        end, true)

        if #left_carriages == 0 then
            train_service.delete_train(entity.train.id)
        end
    end
end

---@param event EventData
function events_control.handle_events(event)
    return EventDispatcher.dispatch(Event.new(event))
end

---@param event EventData
function events_control.open_main_frame(event)
    if not event.entity or not event.entity.valid then
        return
    end

    ---@type LuaEntity
    local entity = event.entity

    if entity.name == mod.defines.prototypes.entity.depot_building.name then
        gui_manager.open_main_frame(Event.new(event))
    end
end

---@param event EventData
function events_control.on_gui_closed(event)
    gui_manager.on_gui_closed(Event.new(event))
end

-----@param event EventData
function events_control.train_create(event)
    train_service.register_train(event.train, event.old_train_id_1, event.old_train_id_2)
end

return events_control