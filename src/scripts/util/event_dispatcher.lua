local public = {}

function public.match_all()
    return function()
        return true
    end
end

---@param event_id uint
function public.match_event(event_id)
    ---@param e scripts.lib.decorator.Event
    return function(e)
        return e.id == event_id
    end
end

---@param handlers table
---@param event scripts.lib.decorator.Event
---@return bool
function public.dispatch(handlers, event)
    local processed = false

    if mod.defines.dev_mode then
        mod.log.debug(
        "Taken event `{1}`",
                {event.string_name },
        "event.dispatcher"
        )
    end

    for _, h in ipairs(handlers) do
        if h.match(event) and h.func(event) then
            processed = true

            mod.log.debug(
                    "Handled event `{1}`",
                    { tostring(event) },
                    "event.dispatcher:" .. (h.handler_source and handler_source or '?')
            )
        end
    end

    return processed
end

return public
