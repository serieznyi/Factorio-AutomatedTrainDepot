local util_entity = require("scripts.util.entity")
local depot_builder = require("scripts.lib.depot_builder")
local gui_manager = require("scripts.gui.manager")
local console = require("scripts.console")
local Event = require("scripts.lib.event.Event")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local train_service = require("scripts.lib.train.train_service")
local logger = require("scripts.lib.logger")

local events_control = {}

function events_control.initialize()
    local handlers = {}

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "events_control")
    end
end

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

    if entity.name == "entity-ghost" and entity.ghost_name == atd.defines.prototypes.entity.depot_building.name then
        depot_builder.build_ghost(entity)
    elseif entity.name == atd.defines.prototypes.entity.depot_building.name then
        local player = event.player_index ~= nil and game.get_player(event.player_index) or nil

        depot_builder.build(entity, player)
    end
end

---@param event EventData
function events_control.entity_rotated(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == atd.defines.prototypes.entity.depot_building.name then
        depot_builder.revert_rotation(entity, event.previous_direction)
    end
end

---@param event EventData
function events_control.entity_dismantled(event)
    ---@type LuaEntity
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == atd.defines.prototypes.entity.depot_building.name then
        events_control._depot_building_dismantle(entity, Event.new(event))
    elseif util_entity.is_rolling_stock(entity) then
        train_service.try_delete_train(entity)
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

    if entity.name == atd.defines.prototypes.entity.depot_building.name then
        gui_manager.open_main_frame(Event.new(event))
    end
end

---@param event EventData
function events_control.on_gui_closed(event)
    gui_manager.on_gui_closed(Event.new(event))
end

---@param entity LuaEntity
---@param event scripts.lib.event.Event
---@return void
function events_control._depot_building_dismantle(entity, event)
    local original_event = event.original_event
    local event_id = original_event.name

    if event_id == defines.events.on_entity_died or event_id == defines.events.script_raised_destroy then
        depot_builder.destroy(entity)
    elseif event_id == defines.events.on_robot_mined_entity then
        depot_builder.try_mine(entity, original_event.buffer, original_event.player_index, original_event.robot)
    end
end

return events_control