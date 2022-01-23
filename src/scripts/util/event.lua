local event_handler = {}

---@param handlers table
---@param event EventData
---@param action table
function event_handler.dispatch_gui(handlers, event, action)
    local processed = false
    local gui_event = action ~= nil

    for _, h in ipairs(handlers) do
        if gui_event and h.gui == action.gui and (h.action == action.action or h.action == nil) then
            if h.func(event, action) then
                mod.util.logger.debug("Event handler for `{1}:{2}` executed", { h.gui, h.action})
                processed = true
            end
        end
    end

    return processed
end

return event_handler