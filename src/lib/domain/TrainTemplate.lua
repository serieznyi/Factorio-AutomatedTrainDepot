local flib_table = require("__flib__.table")

local TrainPart = require("lib.domain.TrainPart")

--- @module lib.domain.TrainTemplate
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
    ---@type string
    clean_station = nil,
    ---@type string
    destination_station = nil,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
}

---@return table
function TrainTemplate:to_table()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        train_color = self.train_color,
        ---@param train_part lib.domain.TrainPart
        train = flib_table.map(self.train or {}, function(train_part)
            return train_part:to_table()
        end),
        enabled = self.enabled,
        amount = self.amount,
        force_name = self.force_name,
        surface_name = self.surface_name,
        clean_station = self.clean_station,
        destination_station = self.destination_station,
    }
end

---@param data table
function TrainTemplate.from_table(data)
    local object = TrainTemplate.new(data.id, context)

    object.name = data.name
    object.icon = data.icon
    object.train_color = data.train_color
    ---@param train_part lib.domain.TrainPart
    object.train = flib_table.map(data.train or {}, function(train_part)
        return TrainPart.from_table(train_part)
    end)
    object.enabled = data.enabled
    object.amount = data.amount
    object.force_name = data.force_name
    object.surface_name = data.surface_name
    object.clean_station = data.clean_station
    object.destination_station = data.destination_station

    return object
end

---@return lib.domain.TrainTemplate
---@param context lib.domain.Context
function TrainTemplate.from_context(id, context)
    return TrainTemplate.new(id, context.surface_name, context.force_name)
end

---@param id uint
---@param surface_name string
---@param force_name string
function TrainTemplate.new(id, surface_name, force_name)
    ---@type lib.domain.TrainTemplate
    local self = {}
    setmetatable(self, { __index = TrainTemplate })

    self.id = id
    self.surface_name = surface_name
    self.force_name = force_name

    return self
end

return TrainTemplate