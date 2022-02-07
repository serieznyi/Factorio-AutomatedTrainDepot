--- @module scripts.lib.domain.TrainPart
local TrainPart = {
    ---@type string
    type = nil,
    ---@type string
    item_name = nil,
    ---@type uint
    direction = nil,
    ---@type bool
    use_any_fuel = nil,
}

TrainPart.TYPE = {
    LOCOMOTIVE = "locomotive",
    CARGO = "cargo",
}

---@return table
function TrainPart:to_table()
    return {
        type = self.type,
        entity = self.item_name,
        direction = self.direction,
        use_any_fuel = self.use_any_fuel,
    }
end

---@param data table
function TrainPart.from_table(data)
    local object = TrainPart.new(data.type)

    object.item_name = data.entity
    object.direction = data.direction
    object.use_any_fuel = data.use_any_fuel

    return object
end

---@param type string
function TrainPart.new(type, item_name)
    ---@type scripts.lib.domain.TrainPart
    local self = {}
    setmetatable(self, { __index = TrainPart })

    self.type = type
    self.item_name = item_name

    return self
end

return TrainPart