local gui = require("__flib__.gui")

local depot = require("extra.logic.services.depot")
--local DepotFrame = require("extra.gui.frame.DepotFrame")

local event_handler = {}

---@param event EventData
function event_handler.reload_settings(event)
    -- TODO process different settings type

    automated_train_depot.settings.refresh()
end

---@param event EventData
function event_handler.build_depot_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == automated_train_depot.constants.entity_names.depot_building then
        depot.build(entity)
    end
end

---@param event EventData
function event_handler.destroy_depot_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == automated_train_depot.constants.entity_names.depot_building then
        depot.destroy(entity)
    end
end

---@param event EventData
function event_handler.handle_gui_event(event)
    local action = gui.read_action(event)

    if action == nil then
        return false
    end

    -- TODO process event

    return true
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

    if entity.name == automated_train_depot.constants.entity_names.depot_building then
        depot.create_gui(player, entity)
    end
end

return event_handler