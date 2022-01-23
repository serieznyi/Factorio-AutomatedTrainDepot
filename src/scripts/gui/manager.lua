local flib_gui = require("__flib__.gui")

local mod_event = require("scripts.util.event")

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

    if tags ~= nil and tags.type == mod.defines.gui.mod_frame_marker_name then
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

---@param event EventData
local function is_event_target_blocked(event)
    local element = event.element or nil
    local player = game.get_player(event.player_index)

    if element == nil then
        return false
    end

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

function manager.init()
    for _, module in ipairs(FRAME_MODULES) do
        module.init()
    end
end

function manager.load()
    for _, module in ipairs(FRAME_MODULES) do
        module.load()
    end
end

---@param event EventData
function manager.dispatch(event)
    local player = game.get_player(event.player_index)
    local processed = false
    local event_data = mod_event.read_event_data(event)
    local event_name = mod_event.event_name(event.name)

    --- Gui event
    if mod_event.is_gui_event(event) and is_event_target_blocked(event) then
        mod.util.logger.debug("Event `{1}` for gui element `{2}` is blocked", {event_name, event.element.name})
        manager.bring_to_front_current_window(player)
        return true
    end

    if event_data == {} then
        return false
    end

    if event_data.trigger_event ~= nil and event_data ~= nil then
        mod.util.logger.debug(
                "Redirect event `{1} ({2})` -> `{3} ({4})`",
                    {
                            event_name,
                            event_data.target,
                            mod_event.event_name(event_data.trigger_event),
                    }
        )

        script.raise_event(
                event_data.trigger_event,
                {
                    target = event_data.target,
                    player_index = player.index,
                }
        )

        return true
    end

    for _, module in ipairs(FRAME_MODULES) do
        if module.dispatch(event, event_data) then
            processed = true
        end
    end

    return processed
end

return manager