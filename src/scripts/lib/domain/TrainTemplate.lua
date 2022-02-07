local flib_table = require("__flib__.table")

local TrainPart = require("scripts.lib.domain.TrainPart")

--- @module scripts.lib.domain.TrainTemplate
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
    trains_quantity = nil,
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
        ---@param train_part scripts.lib.domain.TrainPart
        train = flib_table.map(self.train or {}, function(train_part)
            return train_part:to_table()
        end),
        enabled = self.enabled,
        trains_quantity = self.trains_quantity,
        force_name = self.force_name,
        surface_name = self.surface_name,
        clean_station = self.clean_station,
        destination_station = self.destination_station,
    }
end

function TrainTemplate:increase_trains_quantity()
    self.trains_quantity = self.trains_quantity + 1
end

function TrainTemplate:decrease_trains_quantity()
    if self.trains_quantity == 0 then
        return
    end

    self.trains_quantity = self.trains_quantity - 1
end

---@param data table
function TrainTemplate.from_table(data)
    local object = TrainTemplate.new(data.id)

    object.name = data.name
    object.icon = data.icon
    object.train_color = data.train_color
    ---@param train_part scripts.lib.domain.TrainPart
    object.train = flib_table.map(data.train or {}, function(train_part)
        return TrainPart.from_table(train_part)
    end)
    object.enabled = data.enabled
    object.trains_quantity = data.trains_quantity
    object.force_name = data.force_name
    object.surface_name = data.surface_name
    object.clean_station = data.clean_station
    object.destination_station = data.destination_station

    return object
end

---@return scripts.lib.domain.TrainTemplate
---@param context scripts.lib.domain.Context
function TrainTemplate.from_context(id, context)
    return TrainTemplate.new(id, context.surface_name, context.force_name)
end

---@param id uint
---@param surface_name string
---@param force_name string
function TrainTemplate.new(id, surface_name, force_name)
    ---@type scripts.lib.domain.TrainTemplate
    local self = {}
    setmetatable(self, { __index = TrainTemplate })

    self.id = id
    self.surface_name = surface_name
    self.force_name = force_name

    return self
end

return TrainTemplate