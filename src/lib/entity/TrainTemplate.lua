local flib_table = require("__flib__.table")

local TrainPart = require("lib.entity.TrainPart")

--- @module lib.entity.TrainTemplate
local TrainTemplate = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    ---@type string
    icon = nil,
    ---@type table
    train_color = {255, 255, 255},
    ---@type table
    train = nil,
    ---@type bool
    enabled = nil,
    ---@type uint
    amount = nil,
}

---@return table
function TrainTemplate:to_table()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        train_color = self.train_color,
        ---@param train_part lib.entity.TrainPart
        train = flib_table.map(self.train or {}, function(train_part)
            return train_part:to_table()
        end),
        enabled = self.enabled,
        amount = self.amount,
    }
end

---@param data table
function TrainTemplate.from_table(data)
    local object = TrainTemplate.new(data.id)

    object.name = data.name
    object.icon = data.icon
    object.train_color = data.train_color
    ---@param train_part lib.entity.TrainPart
    object.train = flib_table.map(data.train or {}, function(train_part)
        return TrainPart.from_table(train_part)
    end)
    object.enabled = data.enabled
    object.amount = data.amount
    object.from_table = data.from_table

    return object
end

---@param id uint
function TrainTemplate.new(id)
    ---@type lib.entity.TrainTemplate
    local self = {}
    setmetatable(self, { __index = TrainTemplate })

    self.id = id

    return self
end

return TrainTemplate