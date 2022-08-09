local flib_gui = require("__flib__.gui")

--- @module scripts.lib.event.Event
local Event = {
    ---@type EventData
    original_event = nil,
    ---@type uint
    id = nil,
    ---@type string
    custom_name = nil,
    ---@type table
    action_data = nil,
    ---@type uint
    player_index = nil,
    ---@type LuaGuiElement
    element = nil,
    ---@type table
    _event_names = nil
}

---@param event EventData
---@return scripts.lib.event.Event
function Event.new(event)
    ---@type scripts.lib.event.Event
    local self = {}
    setmetatable(self, { __index = Event, __tostring = function(o) return o:full_name() end })

    assert(event, "event is nil")
    self.original_event = event

    self.action_data = flib_gui.read_action(self.original_event)
    self.custom_name = self.action_data and self.action_data.event or nil
    self.id = self.custom_name and self.custom_name or self.original_event.name
    self.player_index = event.player_index
    self.element = event.element

    return self
end

function Event:full_name()
    local original_name = self:_event_id_to_name(self.original_event.name)
    local custom_name = self:_event_id_to_name(self.custom_name)

    if self.custom_string_name ~= nil then
        return original_name .. "(" .. custom_name .. ")"
    end

    return original_name
end

function Event:player()
    return game.get_player(self.player_index)
end

function Event:tags()
    if self.element == nil or self.element.valid == false then
        return nil
    end

    return flib_gui.get_tags(self.element)
end

---@return bool
function Event:is_gui_event()
    return self.original_event.element ~= nil
end

---@type uint
function Event:_event_id_to_name(id)
    if id == nil then
        return nil
    end

    if Event._event_names == nil then
        self:_load_event_names()
    end

    return Event._event_names[id]
end

function Event:_load_event_names()
    local events_set = { defines.events, atd.defines.events }

    Event._event_names = {}

    for _, events_el in ipairs(events_set) do
        for event_name, event_number in pairs(events_el) do
            if type(event_name) == "string" and string.sub(event_name, 1, 3) == "on_" then
                Event._event_names[event_number] = event_name
            end
        end
    end
end

return Event