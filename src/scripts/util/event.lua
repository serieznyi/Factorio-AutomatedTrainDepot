local mod_gui = require("scripts.util.gui")

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
---@param mediator_name string
function event.dispatch(handlers, event_arg, event_data, mediator_name)
    local processed = false
    local event_name = event.event_name(event_arg.name)
    local event_data_action_name = event_data.action and mod_gui.action_name(event_data.action) or nil
    local event_data_event_name = event_data.event and event.event_name(event_data.event) or nil

    -- todo remove later
    mod.log.debug(
            "Caught event `{1} ({2}:{3})`",
            {
                event_name,
                event_data.target ~= nil and event_data.target or "none",
                event_data_action_name ~= nil and event_data_action_name or (event_data_event_name ~= nil and event_data_event_name or "none"),
            },
            "event.dispatcher:" .. mediator_name
    )

    for _, h in ipairs(handlers) do
        if event_data.target == h.target then
            if
                (event_data.action ~= nil and (h.action == event_data.action or h.action == mod.defines.gui.actions.any)) or
                (h.event ~= nil and h.event == event_arg.name)
            then
                if h.func(event_arg, event_data) then
                    processed = true

                    local action_name = "?"
                    if h.action ~= nil then
                        action_name = mod_gui.action_name(h.action)
                    end

                    mod.log.debug(
                            "Handled event `{1} ({2}:{3})`",
                            { event_name, h.target, action_name},
                            "event.dispatcher:" .. mediator_name
                    )
                end
            end

        end
    end

    return processed
end

return event