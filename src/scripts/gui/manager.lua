local flib_gui = require("__flib__.gui")

local main_frame = require("scripts.gui.frame.main.frame")
local add_group_frame = require("scripts.gui.frame.add_group.frame")
local settings_frame = require("scripts.gui.frame.settings.frame")

local manager = {}

local FRAME_MODULES = {
    main_frame,
    add_group_frame,
    settings_frame,
}

---@param element LuaGuiElement
local function is_mod_frame(element)
    if element.type ~= "frame" then
        return false
    end

    local tags = flib_gui.get_tags(element)

    if tags ~= nil and tags.type == mod.constants.gui.frame_type_name then
        return true
    end

    return false
end

---@param element LuaGuiElement
local function get_element_mod_frame(element)
    if element.type == "frame" and is_mod_frame(element) then
        return element
    end

    if element.parent == nil then
        return nil
    end

    return get_element_mod_frame(element.parent)
end

---@param element LuaGuiElement
---@param player LuaPlayer
local function is_event_target_blocked(element, player)
    local element_frame = get_element_mod_frame(element)

    if element_frame == nil then
        return false
    end

    return player.opened ~= nil and player.opened ~= element_frame
end

function manager.bring_to_front_current_window()
    for _, player in pairs(game.players) do
        if player.opened ~= nil and is_mod_frame(player.opened) then
            player.opened.bring_to_front()
        end
    end
end

function manager.register_remote_interfaces()
    for _, module in ipairs(FRAME_MODULES) do
        for interface_name, functions in pairs(module.remote_interfaces()) do
            if functions ~= {} then
                remote.add_interface(interface_name, functions)
            end
        end
    end
end

function manager.init()
    global.gui = {}
    global.gui_component = {}

    for _, module in ipairs(FRAME_MODULES) do
        module.init()
    end
end

function manager.load()
    for _, module in ipairs(FRAME_MODULES) do
        module.load()
    end
end

function manager.dispatch(action, event)
    local element = event.element
    local player = game.get_player(event.player_index)

    if is_event_target_blocked(element, player) then
        mod.logger.debug(
                "Event `{1}` for gui element `{2}` is blocked",
                {event.name, element.name}
        )
        manager.bring_to_front_current_window(player)
        return false
    end

    for _, frame in ipairs(FRAME_MODULES) do
        if frame.dispatch(action, event) then
            return true
        end
    end

    return false
end

return manager