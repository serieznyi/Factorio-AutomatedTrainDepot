local flib_table = require("__flib__.table")

local main_frame = require("scripts.gui.frame.main_frame")
local add_group_frame = require("scripts.gui.frame.add_group_frame.frame")
local settings_frame = require("scripts.gui.frame.settings")
local depot = require("scripts.depot")

local manager = {}

local REGISTERED_MAIN_FRAMES = {
    main_frame,
    add_group_frame,
    settings_frame,
}

local MAIN_FRAME_NAMES = flib_table.map(REGISTERED_MAIN_FRAMES, function(m) return m.name() end)

---@param element LuaGuiElement
local function is_main_frame(element)
    for _, gui in ipairs(REGISTERED_MAIN_FRAMES) do
        if gui.name() == element.name then
            return true
        end
    end

    return false
end

---@param element LuaGuiElement
local function get_element_main_frame(element)
    if element.type == "frame" and is_main_frame(element) then
        return element
    end

    return get_element_main_frame(element.parent)
end

---@param element LuaGuiElement
---@param player LuaPlayer
local function is_blocked_frame(element, player)
    local event_from_frame = get_element_main_frame(element)

    return player.opened ~= nil and player.opened ~= event_from_frame
end

---@param element LuaGuiElement
local function is_mod_frame(element)
    if element.type ~= "frame" then
        return false
    end

    for _, name in ipairs(MAIN_FRAME_NAMES) do
        if element.name == name then
            return true
        end
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

function manager.register_remote_interfaces()
    for _, module in ipairs(REGISTERED_MAIN_FRAMES) do
        remote.add_interface("automated_train_depot." .. module.name(), module.remote_interfaces())
    end
end

function manager.init()
    global.gui = {}
    global.gui_component = {}

    for _, module in ipairs(REGISTERED_MAIN_FRAMES) do
        module.init()
    end

    --- TODO use interface ?
    add_group_frame.on_form_save(depot.save_group)
end

function manager.load()
    for _, module in ipairs(REGISTERED_MAIN_FRAMES) do
        module.load()
    end

    --- TODO use interface ?
    add_group_frame.on_form_save(depot.save_group)
end

function manager.dispatch(action, event)
    local element = event.element
    local player = game.get_player(event.player_index)

    if is_blocked_frame(element, player) then
        automated_train_depot.logger.debug(
                "Event `{1}` for gui element `{2}` is blocked",
                {event.name, element.name}
        )
        manager.bring_to_front_current_window(player)
        return false
    end

    for _, frame in ipairs(REGISTERED_MAIN_FRAMES) do
        if frame.dispatch(action, event) then
            return true
        end
    end

    return false
end

return manager