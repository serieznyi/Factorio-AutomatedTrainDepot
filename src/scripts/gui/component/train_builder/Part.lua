local flib_gui = require("__flib__.gui")

local logger = require("scripts.lib.logger")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local TrainPart = require("scripts.lib.domain.entity.train.TrainPart")
local structure = require("scripts.gui.component.train_builder.structure")
local Sequence = require("scripts.lib.Sequence")

local component_id_sequence = Sequence()

---@param o1 gui.component.TrainBuilder.Part
---@param o2 gui.component.TrainBuilder.Part
local function compare(o1, o2)
    return o1.id == o2.id
end

--- @module gui.component.TrainBuilder.Part
local Part = {
    ---@type string
    name = nil,
    ---@type uint
    id = nil,
    ---@type LuaPlayer
    player = nil,
    ---@type function
    on_changed = nil,
    ---@type LuaGuiElement
    container = nil,
    refs = {
        ---@type LuaGuiElement
        element = nil,
        ---@type LuaGuiElement
        part_chooser = nil,
        ---@type LuaGuiElement
        delete_button = nil,
        ---@type LuaGuiElement
        carrier_direction_left_button = nil,
        ---@type LuaGuiElement
        carrier_direction_right_button = nil,
    },
}

---@param train_part scripts.lib.domain.entity.train.TrainPart
---@param on_changed function
---@param player LuaPlayer
---@param container LuaGuiElement
function Part.new(container, player, on_changed, train_part)
    ---@type gui.component.TrainBuilder.Part
    local self = {}
    setmetatable(self, { __index = Part, __eq = compare})

    self.id = component_id_sequence:next()

    self.name = "train_part_component_" .. self.id

    self.player = player or nil
    assert(self.player, "player is nil")

    self.container = container
    assert(self.container, "container is nil")

    if on_changed ~= nil then
        self.on_changed = on_changed
    end

    self:_initialize(train_part)

    logger.debug("Component {1} created", {self.name}, self.name)

    return self
end

function Part:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_choose_train_part),
            handler = function(e) return self:_handle_update_train_part(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_change_carrier_direction_click),
            handler = function(e) return self:_handle_change_carrier_direction(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_delete_train_part_click),
            handler = function(e) return self:_handle_delete_train_part(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

function Part:is_empty()
    return self.refs.part_chooser.elem_value == nil
end

function Part:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    self.refs.element.destroy()
end

function Part:read_form()
    local part_chooser = self.refs.part_chooser

    -- if fast call form reading - fail on invalid chooser
    if self.refs.part_chooser.valid == false then
        return nil
    end

    local item_name = part_chooser.elem_value

    if item_name == nil then
        return nil
    end

    local type = self:_get_train_part_type_from_item_name(item_name)
    ---@type scripts.lib.domain.entity.train.TrainPart
    local carrier = TrainPart.new(type, item_name)
    local tags = flib_gui.get_tags(self.refs.carrier_direction_right_button)
    local direction = tags.current_direction

    if type == TrainPart.TYPE.ARTILLERY then
        carrier.direction = direction
    elseif type == TrainPart.TYPE.LOCOMOTIVE then
        carrier.direction = direction
    end

    return carrier
end

---@param event scripts.lib.event.Event
function Part:_handle_update_train_part(event)
    local tags = event:tags()

    if tags == nil or tags.train_part_id ~= self.id then
        return false
    end

    self:_update()

    self:_on_changed_callback_call()

    return true
end

---@param event scripts.lib.event.Event
function Part:_handle_delete_train_part(event)
    local tags = event:tags()

    if tags == nil or tags.train_part_id ~= self.id then
        return false
    end

    self.refs.part_chooser.elem_value = nil

    self:_on_changed_callback_call()

    return true
end

---@param event scripts.lib.event.Event
function Part:_handle_change_carrier_direction(event)
    local tags = event:tags()

    if tags.train_part_id ~= self.id then
        return false
    end

    local direction = tags.direction == atd.defines.train.direction.opposite_direction and atd.defines.train.direction.in_direction or atd.defines.train.direction.opposite_direction

    self:_set_carrier_direction(direction)

    self:_update()

    self:_on_changed_callback_call()

    return true
end

---@param new_direction uint
function Part:_set_carrier_direction(new_direction)
    flib_gui.update(self.refs.carrier_direction_left_button, { tags = { current_direction = new_direction } })
    flib_gui.update(self.refs.carrier_direction_right_button, { tags = { current_direction = new_direction } })
end

---@param element LuaGuiElement
---@return int
function Part:_get_train_part_id(element)
    local tags = flib_gui.get_tags(element)

    return tags.train_part_id
end

---@param train_part scripts.lib.domain.entity.train.TrainPart
function Part:_initialize(train_part)
    self:_register_event_handlers()

    self.refs = flib_gui.build(self.container, { structure.get(self.id) })

    if train_part ~= nil then
        self.refs.part_chooser.elem_value = train_part.prototype_name

        if train_part:has_direction() then
            self:_set_carrier_direction(train_part.direction)
        end
    end

    self:_update()
end

function Part:_update()
    local tags = flib_gui.get_tags(self.refs.carrier_direction_right_button)
    local current_carrier_direction = tags.current_direction

    if self.refs.part_chooser.elem_value == nil then
        return
    end

    local type = self:_get_train_part_type_from_item_name(self.refs.part_chooser.elem_value)
    local has_direction = type ~= TrainPart.TYPE.CARGO

    self.refs.delete_button.visible = true

    if has_direction then
        self.refs.carrier_direction_left_button.visible = (current_carrier_direction == atd.defines.train.direction.in_direction)
        self.refs.carrier_direction_right_button.visible = (current_carrier_direction == atd.defines.train.direction.opposite_direction)
    end
end

---@param value string|nil
---@return bool
function Part:_get_train_part_type_from_item_name(value)
    assert(value, "value is nil")

    local prototype = game.entity_prototypes[value]

    local map = {
        ["locomotive"] = TrainPart.TYPE.LOCOMOTIVE,
        ["artillery-wagon"] = TrainPart.TYPE.ARTILLERY,
        ["cargo-wagon"] = TrainPart.TYPE.CARGO,
        ["fluid-wagon"] = TrainPart.TYPE.CARGO,
    }

    return map[prototype.type]
end

function Part:_is_train_part_selector_cleaned()
    return self.refs.part_chooser.elem_value == nil
end

function Part:_on_changed_callback_call()
    if self.on_changed ~= nil then
        local on_changed = self.on_changed
        on_changed(self)
    end
end

return Part