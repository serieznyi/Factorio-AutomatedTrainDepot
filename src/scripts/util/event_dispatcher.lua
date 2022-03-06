local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")

local public = {}
local private = {}

---@param event_arg EventData
function private.read_event_data(event_arg)
    local event_data = flib_gui.read_action(event_arg)

    if event_data == nil then
        event_data = {}
    end

    event_data.name = public.event_name(event_arg.name)

    if event_data.target == nil then
        event_data.target = event_arg.target
    end

    return event_data
end

local event_name_map

local function init()
    event_name_map = {}

    local events_set = { defines.events, mod.defines.events }

    for _, events_el in ipairs(events_set) do
        for event_name, event_number in pairs(events_el) do
            if string.sub(event_name, 1, 3) == "on_" then
                event_name_map[event_number] = event_name
            end
        end
    end
end

---@param target string
function public.match_target(target)
    ---@param e scripts.lib.decorator.Event
    return function(e)
        if not e:is_gui_event() then
            return false
        end

        return e:target_name() == target
    end
end

function public.match_all_non_gui_events()
    ---@param e scripts.lib.decorator.Event
    return function(e)
        if not e:is_gui_event() then
            return true
        end

        return false
    end
end

---@param target string
---@param action string
function public.match_target_and_action(target, action)
    ---@param e scripts.lib.decorator.Event
    return function(e)
        if not e:is_gui_event() then
            return false
        end

        return e:target_name() == target and e:action_name() == action
    end
end

---@param event_id uint
function public.match_event(event_id)
    ---@param e scripts.lib.decorator.Event
    return function(e)
        return e.id == event_id
    end
end

---@param event_arg EventData
function public.is_gui_event(event_arg)
    return event_arg.element ~= nil
end

---@param event_number uint
function public.event_name(event_number)
    if event_name_map == nil then
        init()
    end

    return event_name_map[event_number] or 'unknown(' .. event_number .. ')'
end

---@param handlers table
---@param event scripts.lib.decorator.Event
---@param source_name string
function public.dispatch(handlers, event, source_name)
    local processed = false

    if false then
        mod.log.debug(
        "Taken event `{1}`",
                {event:name()},
        "event.dispatcher:" .. source_name
        )
    end

    for _, h in ipairs(handlers) do
        if h.match(event) then
            if h.func(event) then
                processed = true

                mod.log.debug(
                        "Handled event `{1}`",
                        { tostring(event) },
                        "event.dispatcher:" .. source_name
                )
            end
        end
    end

    return processed
end

return public
