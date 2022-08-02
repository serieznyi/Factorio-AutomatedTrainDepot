local flib_gui = require("__flib__.gui")

--- @module scripts.lib.decorator.Event
local Event = {
    ---@type EventData
    original_event = nil,
    ---@type uint
    id = nil,
    ---@type string
    string_name = nil,
    ---@type string
    custom_name = nil,
    ---@type string
    custom_string_name = nil,
    ---@type table
    event_additional_data = nil,
    ---@type uint
    player_index = nil,
    ---@type LuaGuiElement
    gui_element = nil,
    ---@type LuaPlayer
    player = nil,
}

---@param obj scripts.lib.decorator.Event
local function to_string(obj)
    return obj.string_name
end
---@param event EventData
---@return scripts.lib.decorator.Event
function Event.new(event)
    ---@type scripts.lib.decorator.Event
    local self = {}
    setmetatable(self, { __index = Event, __tostring = function(o) return o:full_name() end })

    assert(event, "event is nil")
    self.original_event = event
    self.player_index = event.player_index
    self.gui_element = event.element
    self.player = game.get_player(event.player_index)
    self.tags = event.element and flib_gui.get_tags(event.element) or {}

    self:initialize()

    return self
end

---@return table|nil
function Event:initialize()
    self.event_additional_data = flib_gui.read_action(self.original_event)
    self.custom_name = self.event_additional_data and self.event_additional_data.event or nil
    self.custom_string_name = mod.global.event_names[self.custom_name]
    self.string_name = mod.global.event_names[self.original_event.name]
    self.id = self.custom_name and self.custom_name or self.original_event.name
end

---@return string|nil
function Event:target_name()
    local data = self:initialize()

    return data and data.target or nil
end

function Event:full_name()
    local original_name = self.string_name and self.string_name or "<unk>"
    local custom_name = self.custom_string_name and self.custom_string_name or "<unk>"

    if self.custom_string_name ~= nil then
        return custom_name .. "(" .. original_name .. ")"
    end

    return original_name
end

---@return bool
function Event:is_gui_event()
    return self.original_event.element ~= nil
end

return Event