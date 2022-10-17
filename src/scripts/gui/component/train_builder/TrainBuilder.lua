local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local logger = require("scripts.lib.logger")
local RollingStock = require("scripts.lib.domain.entity.template.RollingStock")
local Part = require("scripts.gui.component.train_builder.Part")
local validator = require("scripts.gui.validator")
local Sequence = require("scripts.lib.Sequence")

local component_id_sequence = Sequence()

local function validation_check_has_main_locomotive(field_name, form)
    ---@type scripts.lib.domain.entity.template.RollingStock
    local rolling_stock = form[field_name][1]

    if not rolling_stock or rolling_stock.type == RollingStock.TYPE.LOCOMOTIVE then
        return
    end

    return {"validation-message.first-carrier-must-be-locomotive"}
end

local function validation_check_empty_train(field_name, form)
    local train = form[field_name]

    if train ~= nil and #train > 0 then
        return
    end

    return {"validation-message.trains-is-empty"}
end

local function validation_check_main_locomotive_wrong_direction(field_name, form)
    ---@type scripts.lib.domain.entity.template.RollingStock
    local rolling_stock = form[field_name][1]

    if not rolling_stock or rolling_stock.type ~= RollingStock.TYPE.LOCOMOTIVE then
        return
    end

    if rolling_stock.direction == atd.defines.train.direction.in_direction then
        return
    end

    return {"validation-message.locomotive-direction-in-station"}
end

--- @module gui.component.TrainBuilder
local TrainBuilder = {
    ---@type string
    name = nil,
    ---@type uint
    id = nil,
    ---@type LuaPlayer
    player = nil,
    ---@type function
    on_changed = nil,
    refs = {
        ---@type LuaGuiElement
        container = nil,
    },
    ---@type gui.component.TrainBuilder.Part[]
    parts = {}
}

---@param on_changed function
---@param player LuaPlayer
---@param container LuaGuiElement
---@param train table of scripts.lib.domain.train.RollingStock[]
function TrainBuilder.new(container, player, on_changed, train)
    ---@type gui.component.TrainBuilder
    local self = {}
    setmetatable(self, { __index = TrainBuilder })

    self.player = player or nil
    assert(self.player, "player is nil")

    self.id = component_id_sequence:next()

    self.name = "train_builder_component_" .. self.id

    if on_changed ~= nil then
        self.on_changed = on_changed
    end

    self:_initialize(container, train)

    logger.debug("Component {1} created", {self.name}, self.name)

    return self
end

function TrainBuilder:update()
end

function TrainBuilder:destroy()
    self.refs.container.clear()

    logger.debug("Frame {1} destroyed", {self.name}, self.name)
end

function TrainBuilder:read_form()
    local train = {}

    ---@param el gui.component.TrainBuilder.Part
    for _, el in ipairs(self.parts) do
        local data = el:read_form()

        if data ~= nil then
            table.insert(train, data)
        end
    end

    return train
end

---@return table errors
function TrainBuilder:validate_form()
    local form_data = self:read_form()
    local validator_rules = {
        validator.check( "train", validator.match_by_name({"train"}), validation_check_empty_train),
        validator.check("train", validator.match_by_name({"train"}), validation_check_has_main_locomotive),
        validator.check("train", validator.match_by_name({"train"}), validation_check_main_locomotive_wrong_direction),
    }

    return validator.validate(validator_rules, { train = form_data })
end

---@param container LuaGuiElement
---@param train scripts.lib.domain.entity.template.RollingStock[]
function TrainBuilder:_initialize(container, train)
    self.refs = flib_gui.build(container, { self:_structure() })

    if train ~= nil then
        for _, rolling_stock in ipairs(train) do
            self:_add_new_part(rolling_stock)
        end
    end

    self:_add_new_part()
end

---@return gui.component.TrainBuilder.Part
function TrainBuilder:_get_last_part()
    return self.parts[#self.parts]
end

---@param rolling_stock scripts.lib.domain.entity.template.RollingStock
---@return gui.component.TrainBuilder.Part
function TrainBuilder:_add_new_part(rolling_stock)
    local part = Part.new(
            self.refs.container,
            self.player,
            function(part) return self:_process_part_changing(part) end,
            rolling_stock
    )

    self:_add_part(part)

    return part
end

---@param part gui.component.TrainBuilder.Part
function TrainBuilder:_process_part_changing(part)
    local last_part = self:_get_last_part()

    if part:is_empty() and part.id ~= last_part.id then
        self:_remove_part(part)
    elseif not part:is_empty() and part.id == last_part.id then
        self:_add_new_part()
    end

    self:_on_changed_callback_call()
end

function TrainBuilder:_on_changed_callback_call()
    if self.on_changed ~= nil then
        local on_changed = self.on_changed
        on_changed(self)
    end
end

---@param part gui.component.TrainBuilder.Part
function TrainBuilder:_add_part(part)
    table.insert(self.parts, part)
end

---@param part gui.component.TrainBuilder.Part
function TrainBuilder:_remove_part(part)
    part:destroy()
    local index = flib_table.find(self.parts, part)

    table.remove(self.parts, index)
end

function TrainBuilder:_structure()
    return {
        type = "flow",
        ref = {"container"},
        direction = "horizontal",
    }
end

return TrainBuilder