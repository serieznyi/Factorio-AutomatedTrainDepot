local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

---------------------------------------------------------------------------
-- -- -- TYPES ; BEGIN
---------------------------------------------------------------------------

---@module gui.frame.Frame
local Frame = {
    ---@type string
    name = nil
}

---@return void
function Frame:destroy() end

---@return LuaGuiElement
function Frame:window() end

---------------------------------------------------------------------------
-- -- -- TYPES ; END
---------------------------------------------------------------------------

--- @class gui.component.Frame
--- @method show

local event_dispatcher = require("scripts.util.event_dispatcher")
local MainFrame = require("scripts.gui.frame.main.MainFrame")
local AddTemplateFrame = require("scripts.gui.frame.add_template.AddTemplateFrame")
local SettingsFrame = require("scripts.gui.frame.settings.SettingsFrame")

local manager = {}
local frame_stack = {}
local event_handlers = {}

---------------------------------------------------------------------------
-- -- -- OTHER
---------------------------------------------------------------------------

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

---@param frame gui.component.Frame
---@param player LuaPlayer
local function switch_on_frame(frame, player)
    local lua_frame = frame:window()
    lua_frame.bring_to_front()

    -- !!!important. Add to stack before real open window
    frame_stack.frame_stack_push(frame)

    player.opened = lua_frame
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
-- -- -- FRAME STACK
---------------------------------------------------------------------------

---@return table
function frame_stack.all()
    return flib_table. array_copy(mod.global.gui.frames_stack)
end

---@param frame gui.frame.Frame
function frame_stack.frame_stack_push(frame)
    if frame_stack.exists(frame) then
        return
    end

    table.insert(mod.global.gui.frames_stack, frame)
end

---@param frame gui.frame.Frame
---@return bool
function frame_stack.exists(frame)
    ---@param frame_in_stack gui.frame.Frame
    for _, frame_in_stack in ipairs(mod.global.gui.frames_stack) do
        if frame_in_stack.name == frame.name then
            return true
        end
    end

    return false
end

---@return bool
function frame_stack.empty()
    return #mod.global.gui.frames_stack == 0
end

function frame_stack.frame_stack_pop()
    if mod.global.gui.frames_stack == {} then
        return
    end

    local last_index = #mod.global.gui.frames_stack;
    local frame = mod.global.gui.frames_stack[last_index]

    table.remove(mod.global.gui.frames_stack, last_index)

    return frame
end

---@return gui.frame.Frame
function frame_stack.frame_stack_last()
    if #mod.global.gui.frames_stack == 0 then
        return
    end

    local last_index = #mod.global.gui.frames_stack;

    return mod.global.gui.frames_stack[last_index]
end

---------------------------------------------------------------------------
-- -- -- EVENT HANDLERS
---------------------------------------------------------------------------

---@param event scripts.lib.decorator.Event
function event_handlers.handle_close_frame_by_event(event)
    local event_window = get_parent_frame_for_gui_element(event.gui_element)

    assert(event_window, 'window not found')

    ---@param v gui.frame.Frame
    local filtered = flib_table.filter(frame_stack.all(), function(v)
        return v:window() == event_window
    end, true)

    local frame = filtered[1]

    assert(frame, 'frame not found')

    manager.close_frame(frame)
end

function event_handlers.event_handlers()
    return {
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_close_main_frame_click),
            func = event_handlers.handle_close_frame_by_event,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_close_add_template_frame_click),
            func = event_handlers.handle_close_frame_by_event,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_settings_frame_close_click),
            func = event_handlers.handle_close_frame_by_event,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_adding_template_frame_click),
            func = event_handlers.handle_add_template_frame_open,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_editing_template_frame_click),
            func = event_handlers.handle_add_template_frame_open,
            handler_source = "gui_manager"
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_settings_frame_click),
            func = event_handlers.handle_settings_frame_open,
            handler_source = "gui_manager"
        },
    }
end

---@param event scripts.lib.decorator.Event
function event_handlers.handle_add_template_frame_open(event)
    local parent_frame = frame_stack.frame_stack_last()
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local train_template_id = event.tags ~= nil and event.tags.train_template_id or nil
    local frame = AddTemplateFrame.new(parent_frame, player, train_template_id)

    switch_on_frame(frame, player)
end

---@param event scripts.lib.decorator.Event
function event_handlers.handle_settings_frame_open(event)
    local parent_frame = frame_stack.frame_stack_last()
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local frame = SettingsFrame.new(parent_frame, player)

    switch_on_frame(frame, player)
end

---@param event scripts.lib.decorator.Event
function event_handlers.handle_main_frame_open(event)
    ---@type LuaPlayer
    local player = game.get_player(event.player_index)
    local frame = MainFrame.new(player)

    switch_on_frame(frame, player)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

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

---@param e scripts.lib.decorator.Event
function manager.open_main_frame(e)
    event_handlers.handle_main_frame_open(e)
end

---@param event scripts.lib.decorator.Event
function manager.dispatch(event)
    local processed = event_dispatcher.dispatch(event_handlers.event_handlers(), event)

    for _, frame in ipairs(frame_stack.all()) do
        if frame:dispatch(event) then
            processed = true
        end
    end

    return processed
end

---@param frame gui.frame.Frame
function manager.close_frame(frame)
    frame:destroy()

    frame_stack.frame_stack_pop()
end

---@param event scripts.lib.decorator.Event
function manager.on_gui_closed(event)
    if event.gui_element == nil or frame_stack.empty() then
        return
    end

    local closed_window = event.gui_element
    local last_frame = frame_stack.frame_stack_last()
    local parent_frame = last_frame.parent_frame
    local last_frame_window = last_frame:window()
    local player = game.get_player(event.player_index)

    if closed_window == last_frame_window then
        frame_stack.frame_stack_pop()
        last_frame:destroy()

        if parent_frame ~= nil then
            switch_on_frame(parent_frame, player)
        end
    end
end

return manager