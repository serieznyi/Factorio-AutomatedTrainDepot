local depot_building = require("scripts.depot.depot_building")
local depot = require("scripts.depot.depot")
local gui_main_frame = require("scripts.gui.frame.main.frame")
local gui_manager = require("scripts.gui.manager")
local console = require("scripts.console")

local event_handler = {}

---@param event EventData
function event_handler.reload_settings(event)
    console.load(event.player_index)
end

---@param event EventData
function event_handler.build_depot_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == mod.defines.entity.depot_building.name then
        depot_building.build(entity)
    end
end

---@param event EventData
function event_handler.destroy_depot_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == mod.defines.entity.depot_building.name then
        depot_building.destroy(entity)
    end
end

---@param event EventData
function event_handler.handle_gui_event(event)
    return gui_manager.dispatch(event)
end

---@param event EventData
function event_handler.open_gui(event)
    if
        event_handler.handle_gui_event(event) == true
        or not event.entity
        or not event.entity.valid
    then
        return
    end

    ---@type LuaEntity
    local entity = event.entity
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)

    if entity.name == mod.defines.entity.depot_building.name then
        gui_main_frame.open(player)
    end
end

function event_handler.bring_to_front_current_window()
    gui_manager.bring_to_front_current_window()
end

function event_handler.on_train_created(e)
    local player = e.get_player

    depot.register_trains()
end

---@param event EventData
function event_handler.pass_to_gui(event)
    gui_manager.dispatch(event)
end

return event_handler