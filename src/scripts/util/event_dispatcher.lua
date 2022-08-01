local public = {}

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

function public.match_all()
    return function()
        return true
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
