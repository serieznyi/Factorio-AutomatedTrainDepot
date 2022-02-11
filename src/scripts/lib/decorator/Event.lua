local flib_gui = require("__flib__.gui")

--- @module scripts.lib.decorator.Event
local public = {
    ---@type EventData
    original_event = nil,
    ---@type uint
    id = nil,
    ---@type string
    _name = nil,
    ---@type table
    _action_data = nil,
    ---@type uint
    player_index = nil,
    ---@type LuaGuiElement
    gui_element = nil,
}
local private = {
    event_name_map = nil
}

---@param obj scripts.lib.decorator.Event
function private.to_string(obj)
    return obj:name()
end

function private.init_event_names()
    private.event_name_map = {}

    local events_set = { defines.events, mod.defines.events }

    for _, events_el in ipairs(events_set) do
        for event_name, event_number in pairs(events_el) do
            if string.sub(event_name, 1, 3) == "on_" then
                private.event_name_map[event_number] = event_name
            end
        end
    end
end

---@return string
function public:name()
    if self._name ~= nil then
        return self._name
    end

    if private.event_name_map == nil then
        private.init_event_names()
    end

    self._name = private.event_name_map[self.id]

    return self._name
end

---@return table|nil
function public:get_gui_event_data()
    if self._action_data ~= nil then
        return self._action_data
    end

    if not self:is_gui_event() then
        return nil
    end

    local action_data = flib_gui.read_action(self.original_event)

    if action_data == nil then
        return nil
    end

    action_data.name = self:name(self.original_event.name)

    self._action_data = action_data

    return action_data
end

---@return string|nil
function public:target_name()
    local data = self:get_gui_event_data()

    return data ~= nil and data.target or nil
end

---@return string|nil
function public:action_name()
    local data = self:get_gui_event_data()

    return data ~= nil and data.action or nil
end

---@return bool
function public:is_gui_event()
    return self.original_event.element ~= nil
end

---@param event EventData
---@return scripts.lib.decorator.Event
function public.new(event)
    ---@type scripts.lib.decorator.Event
    local self = {}
    setmetatable(self, { __index = public, __tostring = private.to_string })

    assert(event, "event is nil")
    self.id = event.name
    self.original_event = event
    self.player_index = event.player_index
    self.gui_element = event.element

    return self
end

return public