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

---@param event_number uint
function event.event_name(event_number)
    if event_name_map == nil then
        init()
    end

    return event_name_map[event_number] or 'unknown(' .. event_number .. ')'
end

---@param handlers table
---@param event_arg EventData
---@param action table
function event.dispatch(handlers, event_arg, action)
    local processed = false
    local gui_event = action ~= nil
    local event_name = event.event_name(event_arg.name)

    for _, h in ipairs(handlers) do
        if gui_event and h.target == action.target and (h.action == action.action or h.action == nil) then
            if h.func(event_arg, action) then
                mod.util.logger.debug("Event `{1} ({2}:{3})` handled", { event_name, h.target, h.action or "unknown"})
                processed = true
            end
        elseif h.event ~= nil and h.event == event_arg.name then
            if h.func(event_arg) then
                mod.util.logger.debug("Event `{1}` handled", { event_name })
                processed = true
            end
        end
    end

    return processed
end

return event