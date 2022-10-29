local logger = require("scripts.lib.logger")
local util_table = require("scripts.util.table")

local EventDispatcher = {
    handlers = {},
}

EventDispatcher.LOGGING_ENABLED = false
EventDispatcher.LOGGING_SUPPRESS_EVENT_NAMES = {
    defines.events.on_train_changed_state,
}

---@param match function
---@param handler function
---@param source_name string
function EventDispatcher.register_handler(match, handler, source_name)
    assert(match, "match is nil")
    assert(handler, "handler is nil")
    assert(source_name, "source_name is nil")

    if EventDispatcher.handlers[source_name] == nil then
        EventDispatcher.handlers[source_name] = {}
    end

    table.insert(
        EventDispatcher.handlers[source_name],
        {match = match, handler = handler}
    )
end

---@param source_name string
function EventDispatcher.unregister_handlers_by_source(source_name)
    assert(source_name, "source_name is nil")

    local source_handlers = EventDispatcher.handlers[source_name] ~= nil and EventDispatcher.handlers[source_name] or {}

    for i, _ in ipairs(source_handlers) do
        -- dispatcher fail if remove all source in one step
        EventDispatcher.handlers[source_name][i] = nil
    end
end

function EventDispatcher.match_all()
    return function()
        return true
    end
end

---@param event_id uint
function EventDispatcher.match_event(event_id)
    ---@param e scripts.lib.event.Event
    return function(e)
        return e.id == event_id
    end
end

---@param event scripts.lib.event.Event
---@return bool
function EventDispatcher.dispatch(event)
    local processed = false

    if EventDispatcher.LOGGING_ENABLED and not EventDispatcher._is_suppressed(event.id) then
        logger.debug("Taken event `{1}`", { event:full_name() }, "EventDispatcher")
    end

    for source_name, source_handlers in pairs(EventDispatcher.handlers) do
        for _, h in ipairs(source_handlers) do
            if h.match(event) and h.handler(event) then
                processed = true

                if EventDispatcher.LOGGING_ENABLED and not EventDispatcher._is_suppressed(event.id) then
                    logger.debug(
                        "Handled event {1} for {2}",
                        { tostring(event), source_name },
                        "EventDispatcher"
                    )
                end
            end
        end
    end

    return processed
end

---@param event_name uint
function EventDispatcher._is_suppressed(event_name)
    return util_table.find(EventDispatcher.LOGGING_SUPPRESS_EVENT_NAMES, event_name) ~= nil
end

return EventDispatcher
