local flib_gui = require("__flib__.gui")

local event = {}

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

---@param event_arg EventData
function event.is_gui_event(event_arg)
    return event_arg.element ~= nil
end

---@param event_number uint
function event.event_name(event_number)
    if event_name_map == nil then
        init()
    end

    return event_name_map[event_number] or 'unknown(' .. event_number .. ')'
end

---@param handlers table
---@param event_arg EventData
---@param event_data table
function event.dispatch(handlers, event_arg, event_data)
    local processed = false
    local gui_event = event_arg.element ~= nil
    local event_name = event.event_name(event_arg.name)

    for _, h in ipairs(handlers) do
        if event_data.target == h.target then
            if (event_data.action ~= nil and (h.action == event_data.action or h.action == mod.defines.gui.actions.any)) or (h.event ~= nil and h.event == event_arg.name) then
                if h.func(event_arg, event_data) then
                    processed = true

                    if gui_event then
                        mod.util.logger.debug("Event `{1} ({2}:{3})` handled", { event_name, h.target, h.action or "unknown"})
                    else
                        mod.util.logger.debug("Event `{1}` handled", { event_name })
                    end
                end
            end

        end
    end

    return processed
end

return event