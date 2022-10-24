--- @module scripts.lib.domain.entity.template.RollingStock
local RollingStock = {
    ---@type string
    type = nil,
    ---@type string
    prototype_name = nil,
    ---@type string
    direction = nil,
}

RollingStock.TYPE = {
    LOCOMOTIVE = "locomotive",
    CARGO = "cargo",
    ARTILLERY = "artillery",
}

---@return table
function RollingStock:to_table()
    return {
        type = self.type,
        prototype_name = self.prototype_name,
        direction = self.direction,
    }
end

---@type bool
function RollingStock:is_locomotive()
    return self.type == RollingStock.TYPE.LOCOMOTIVE
end

---@type bool
function RollingStock:has_direction()
    return self.type == RollingStock.TYPE.LOCOMOTIVE or self.type == RollingStock.TYPE.ARTILLERY
end

---@return uint train part forming time in seconds (without multiplier)
function RollingStock:get_forming_time()
    ---@type LuaRecipe
    local recipe = game.recipe_prototypes[self.prototype_name]

    return recipe.energy
end

---@param data table
function RollingStock.from_table(data)
    local object = RollingStock.new(data.type)

    object.prototype_name = data.prototype_name
    object.direction = data.direction

    return object
end

---@param type string
function RollingStock.new(type, prototype_name)
    ---@type scripts.lib.domain.entity.template.RollingStock
    local self = {}
    setmetatable(self, { __index = RollingStock })

    self.type = type
    self.prototype_name = prototype_name

    return self
end

return RollingStock