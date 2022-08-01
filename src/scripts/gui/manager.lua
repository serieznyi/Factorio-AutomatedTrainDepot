local flib_gui = require("__flib__.gui")

local event_dispatcher = require("scripts.util.event_dispatcher")
local MainFrame = require("scripts.gui.frame.main.MainFrame")
local AddTemplateFrame = require("scripts.gui.frame.add_template.AddTemplateFrame")
local SettingsFrame = require("scripts.gui.frame.settings.SettingsFrame")

local manager = {}

-- todo move on some global loader ?
local function load_event_names()
    local events_set = { defines.events, mod.defines.events }

    for _, events_el in ipairs(events_set) do
        for event_name, event_number in pairs(events_el) do
            if type(event_name) == "string" and string.sub(event_name, 1, 3) == "on_" then
                mod.global.event_names[event_number] = event_name
            end
        end
    end
end

local function handle_main_frame_close(event)
    mod.global.frames[mod.defines.gui.frames.main.name]:destroy()
end

local function handle_add_template_frame_close(event)
    mod.global.frames[mod.defines.gui.frames.add_template.name]:destroy()
end

local function handle_settings_frame_close(event)
    mod.global.frames[mod.defines.gui.frames.settings.name]:destroy()
end

---@param event scripts.lib.decorator.Event
local function handle_add_template_frame_open(event)
    local player = game.get_player(event.player_index)

    local frame = AddTemplateFrame.new(player)
    mod.global.frames[frame.name] = frame

    frame:show()
end

---@param event scripts.lib.decorator.Event
local function handle_settings_frame_open(event)
    local player = game.get_player(event.player_index)

    local frame = SettingsFrame.new(player)
    mod.global.frames[frame.name] = frame

    frame:show()
end

---@param event scripts.lib.decorator.Event
local function handle_edit_template_frame_open(event)
    local player = game.get_player(event.player_index)

    local frame = AddTemplateFrame.new(player, event.tags.train_template_id)
    mod.global.frames[frame.name] = frame

    frame:show()
end

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

---@param player LuaPlayer
local function is_main_frame_opened(player)
    return false -- todo add real check
end

local function event_handlers()
    return {
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_close_main_frame_click),
            func = handle_main_frame_close,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_close_add_template_frame_click),
            func = handle_add_template_frame_close,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_settings_frame_close_click),
            func = handle_settings_frame_close,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_adding_template_frame_click),
            func = handle_add_template_frame_open,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_editing_template_frame_click),
            func = handle_edit_template_frame_open,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_settings_frame_click),
            func = handle_settings_frame_open,
            handler_source = "gui_manager"
        },
    }
end

function manager.init()
end

function manager.load()
    mod.global.gui = {
        frame = {},
        component = {},
        frames_stack = {}
    }

    load_event_names()
end

---@param player LuaPlayer
function manager.open_main_frame(player)
    if is_main_frame_opened(player) then
        return
    end

    local frame = MainFrame.new(player)
    mod.global.frames[frame.name] = frame

    frame:show()
end

---@param event scripts.lib.decorator.Event
function manager.dispatch(event)
    local processed = event_dispatcher.dispatch(event_handlers(), event)

    for _, frame in pairs(mod.global.frames) do
        if frame:dispatch(event) then
            processed = true
        end
    end

    return processed
end

return manager