local util_table = require("scripts.util.table")

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
    CARGO_WAGON = "cargo-wagon",
    ARTILLERY_WAGON = "artillery-wagon",
    FLUID_WAGON = "fluid-wagon",
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

---@return table<string, uint>
function RollingStock:to_items()
    return {[self.prototype_name] = 1}
end

---@type bool
function RollingStock:has_direction()
    return self.type == RollingStock.TYPE.LOCOMOTIVE or self.type == RollingStock.TYPE.ARTILLERY_WAGON
end

---@return uint train part form time in seconds (without multiplier)
function RollingStock:get_form_time()
    ---@type LuaRecipe
    local recipe = game.recipe_prototypes[self.prototype_name]

    return recipe.energy
end

---@param data table
function RollingStock.from_table(data)
    local object = RollingStock.new(data.type, data.prototype_name)

    util_table.fill_assoc(object, data)

    return object
end

---@param type string
function RollingStock.new(type, prototype_name)
    ---@type scripts.lib.domain.entity.template.RollingStock
    local self = {}
    setmetatable(self, { __index = RollingStock })

    self.type = assert(type, "type is nil")
    self.prototype_name = assert(prototype_name, "prototype_name is nil")

    return self
end

return RollingStock