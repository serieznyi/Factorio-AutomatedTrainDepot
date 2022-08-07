local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local MainFrame = require("scripts.gui.frame.main.MainFrame")
local AddTemplateFrame = require("scripts.gui.frame.add_template.AddTemplateFrame")
local SettingsFrame = require("scripts.gui.frame.settings.SettingsFrame")
local frame_stack = require("scripts.gui.frame_stack")

local manager = {}
local event_handlers = {}

---------------------------------------------------------------------------
-- -- -- OTHER
---------------------------------------------------------------------------

---@param frame gui.frame.Frame
---@param player LuaPlayer
local function switch_on_frame(frame)
    frame:bring_to_front()

    -- !!!important. Add to stack before real open window
    frame_stack.frame_stack_push(frame)

    frame:opened()
end

---@param element LuaGuiElement
local function get_parent_frame_for_gui_element(element)
    if element.type == "frame" then
        local tags = flib_gui. get_tags(element)

        if tags.atd_frame ~= nil then
            return element
        end
    end

    if element.parent == nil then
        return nil
    end

    return get_parent_frame_for_gui_element(element.parent)
end

---------------------------------------------------------------------------
-- -- -- EVENT HANDLERS
---------------------------------------------------------------------------

---@param event scripts.lib.event.Event
function event_handlers.handle_close_frame_by_event(event)
    local event_window = get_parent_frame_for_gui_element(event.element)

    assert(event_window, 'window not found')

    ---@param v gui.frame.Frame
    local filtered = flib_table.filter(frame_stack.all(), function(v)
        return v:window() == event_window
    end, true)

    local frame = filtered[1]

    assert(frame, 'frame not found')

    manager.close_frame(frame)
end

---@param event scripts.lib.event.Event
function event_handlers.handle_add_template_frame_open(event)
    local parent_frame = frame_stack.frame_stack_last()
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local train_template_id = event:tags() ~= nil and event:tags().train_template_id or nil
    local frame = AddTemplateFrame:new(parent_frame, player, train_template_id)

    switch_on_frame(frame)
end

---@param event scripts.lib.event.Event
function event_handlers.handle_settings_frame_open(event)
    local parent_frame = frame_stack.frame_stack_last()
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local frame = SettingsFrame:new(parent_frame, player)

    switch_on_frame(frame)
end

---@param event scripts.lib.event.Event
function event_handlers.handle_background_dimmer_click(event)
    local owner_name = event.action_data.owner_name

    ---@param frame gui.frame.Frame
    for _, frame in ipairs(frame_stack.all()) do
        if frame.name == owner_name then
            frame:bring_to_front()
        end
    end
end

---@param event scripts.lib.event.Event
function event_handlers.handle_main_frame_open(event)
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local frame = MainFrame:new(player)

    switch_on_frame(frame)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function manager.load()
    manager.register_events()
end

---@param e scripts.lib.event.Event
function manager.open_main_frame(e)
    event_handlers.handle_main_frame_open(e)
end

function manager.register_events()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_close_main_frame_click),
            handler = event_handlers.handle_close_frame_by_event,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_close_add_template_frame_click),
            handler = event_handlers.handle_close_frame_by_event,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_settings_frame_close_click),
            handler = event_handlers.handle_close_frame_by_event,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_open_adding_template_frame_click),
            handler = event_handlers.handle_add_template_frame_open,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_open_editing_template_frame_click),
            handler = event_handlers.handle_add_template_frame_open,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_open_settings_frame_click),
            handler = event_handlers.handle_settings_frame_open,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_background_dimmer_click),
            handler = event_handlers.handle_background_dimmer_click,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "gui_manager")
    end
end

---@param frame gui.frame.Frame
function manager.close_frame(frame)
    local parent_frame = frame.parent_frame
    frame_stack.frame_stack_pop()
    frame:destroy()

    if parent_frame ~= nil then
        switch_on_frame(parent_frame)
    end
end

---@param event scripts.lib.event.Event
function manager.on_gui_closed(event)
    if event.element == nil or frame_stack.empty() then
        return
    end

    local last_frame = frame_stack.frame_stack_last()
    local closed_window = event.element
    local last_frame_window = last_frame:window()

    if closed_window == last_frame_window then
        manager.close_frame(last_frame)
    end
end

return manager