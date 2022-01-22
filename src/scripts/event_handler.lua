local gui = require("__flib__.gui")

local depot = require("scripts.depot")
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

    if entity.name == mod.constants.entity_names.depot_building then
        depot.build(entity)
    end
end

---@param event EventData
function event_handler.destroy_depot_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == mod.constants.entity_names.depot_building then
        depot.destroy(entity)
    end
end

---@param event EventData
function event_handler.handle_gui_event(event)
    local action = gui.read_action(event)

    if action == nil then
        return false
    end

    mod.logger.debug(
            "Gui event `{1}:{2}` triggered",
            {action.gui, action.action}
    )

    return gui_manager.dispatch(action, event)
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

    if entity.name == mod.constants.entity_names.depot_building then
        gui_main_frame.open(player)
    end
end

function event_handler.bring_to_front_current_window()
    gui_manager.bring_to_front_current_window()
end

return event_handler