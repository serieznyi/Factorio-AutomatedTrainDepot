local flib_gui = require("__flib__.gui")

local manager = {}

local FRAME_MODULES = {
    require("scripts.gui.frame.main.frame"),
    require("scripts.gui.frame.add_template.frame"),
    require("scripts.gui.frame.settings.frame"),
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

---@param event scripts.lib.decorator.Event
local function is_event_blocked(event)
    if not event:is_gui_event() then
        return false
    end

    local element = event.gui_element
    local element_frame = get_element_mod_frame(element)

    if element_frame == nil then
        return false
    end

    local player = game.get_player(event.player_index)

    if player.opened ~= nil and player.opened ~= element_frame then
        mod.log.debug(
                "Event `{1}` for gui element `{2}` is blocked",
                {
                    event:name(),
                    element.name
                }
        )

        manager.bring_to_front_current_window(player)

        return true
    end

    return false
end

function manager.bring_to_front_current_window()
    for _, player in pairs(game.players) do
        if player.opened ~= nil and is_mod_frame(player.opened) then
            player.opened.bring_to_front()
        end
    end
end

function manager.init()
    global.gui = {
        frame = {},
        component = {},
    }

    for _, module in ipairs(FRAME_MODULES) do
        module.init()
    end
end

function manager.load()
    for _, module in ipairs(FRAME_MODULES) do
        module.load()
    end
end

-- TODO use on user banned, deleted, logout, ...
---@param player LuaPlayer
function manager.clean(player)
    for _, module in ipairs(FRAME_MODULES) do
        module.clean(player)
    end
end

---@param event scripts.lib.decorator.Event
function manager.dispatch(event)
    local processed = false

    -- todo frame move not blocked
    if is_event_blocked(event) then
        return true
    end

    if not event:is_gui_event() then
        return false
    end

    for _, module in ipairs(FRAME_MODULES) do
        if module.dispatch(event) then
            processed = true
        end
    end

    return processed
end

return manager