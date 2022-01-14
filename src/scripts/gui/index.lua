local main_frame = require("scripts.gui.main_frame")
local add_group_frame = require("scripts.gui.add_group_frame")
local locomotive_configuration_frame = require("scripts.gui.locomotive_configuration_frame")

local index = {}

local REGISTERED_MAIN_FRAMES = {
    main_frame,
    add_group_frame,
    locomotive_configuration_frame,
}

local EVENT_HANDLERS = {
    [main_frame.name()] = function(a, e) main_frame.dispatch(a, e) end,
    [add_group_frame.name()] = function(a, e) add_group_frame.dispatch(a, e) end,
    [locomotive_configuration_frame.name()] = function(a, e) locomotive_configuration_frame.dispatch(a, e) end,
}

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

function index.bring_to_front_current_window()
    for _, player in pairs(game.players) do
        if player.opened ~= nil and player.opened.type == "frame" then
            player.opened.bring_to_front()
        end
    end
end

function index.register_remote_interfaces()
    for _, module in ipairs(REGISTERED_MAIN_FRAMES) do
        remote.add_interface(module.name(), module.remote_interfaces())
    end
end

function index.init()
    global.gui = {}

    for _, module in ipairs(REGISTERED_MAIN_FRAMES) do
        module.init()
    end
end

function index.dispatch(action, event)
    local element = event.element
    local player = game.get_player(event.player_index)

    if is_blocked_frame(element, player) then
        automated_train_depot.logger.debug(
                "Event `{1}` for gui element `{2}` is blocked",
                {event.name, element.name}
        )
        --index.bring_to_front_current_window(player)
        return
    end

    local handler = EVENT_HANDLERS[action.gui]

    if handler ~= nil then
        return handler(action, event)
    end

    return false
end

return index