local gui = require("__flib__.gui")

local depot = require("extra.logic.services.depot")
local DepotFrame = require("extra.gui.frame.DepotFrame")

local default_controller = {}

function default_controller:on_runtime_mod_setting_changed()
    -- TODO process different settings type

    automated_train_depot.settings.refresh()
end

---@param event EventData
function default_controller:on_build_entity(event)
    local entity = event.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == automated_train_depot.constants.entity_names.depot_building then
        depot:build(entity)
    end
end

---@param event EventData
function default_controller:on_deconstruct_entity(event)
    local entity = event.entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == automated_train_depot.constants.entity_names.depot_building then
        depot:destroy(entity)
    end
end

---@param event EventData
function default_controller:handle_gui_event(event)
    local action = gui.read_action(event)

    if action == nil then
        return
    end

    automated_train_depot.console:debug(event.element)
    automated_train_depot.console:debug(action.target)
    automated_train_depot.console:debug(action.action)

    -----@type LuaPlayer
    --local player = game.get_player(event.player_index)
    --player.opened = nil
end

---@param event EventData
function default_controller:open_depot_window(event)
    if
        event.gui_type ~= defines.gui_type.entity
        or event.entity.name ~= automated_train_depot.constants.entity_names.depot_building
    then
        return
    end

    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    ---@type LuaEntity
    local entity = event.entity
    local surface_name = entity.surface.name

    --- @type DepotFrame
    local depot_frame = automated_train_depot.depots[surface_name].gui

    if depot_frame == nil then
        depot_frame = DepotFrame(entity, player)
        automated_train_depot.gui[surface_name].gui = depot_frame
    end

    player.opened = nil
    player.opened = depot_frame.frame
end

return default_controller