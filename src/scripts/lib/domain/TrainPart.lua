local private = {}

---@return uint forming time in seconds for locomotive and this equipment (without multiplier)
function private.get_forming_time_for_locomotive()
    ---@type LuaRecipe
    local locomotive_recipe = game.recipe_prototypes["locomotive"]
    local time = locomotive_recipe.energy

    --todo inventory

    return time
end

--- @module scripts.lib.domain.TrainPart
local TrainPart = {
    ---@type string
    type = nil,
    ---@type string
    prototype_name = nil,
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
        prototype_name = self.prototype_name,
        direction = self.direction,
        use_any_fuel = self.use_any_fuel,
    }
end

---@return uint train part forming time in seconds (without multiplier)
function TrainPart:get_forming_time()
    if self.type == TrainPart.TYPE.CARGO then
        ---@type LuaRecipe
        local cargo_wagon_recipe = game.recipe_prototypes["cargo-wagon"]

        -- todo use different type for different cargo type ?

        return cargo_wagon_recipe.energy
    end

    return private.get_forming_time_for_locomotive()
end

---@param data table
function TrainPart.from_table(data)
    local object = TrainPart.new(data.type)

    object.prototype_name = data.prototype_name
    object.direction = data.direction
    object.use_any_fuel = data.use_any_fuel

    return object
end

---@param type string
function TrainPart.new(type, prototype_name)
    ---@type scripts.lib.domain.TrainPart
    local self = {}
    setmetatable(self, { __index = TrainPart })

    self.type = type
    self.prototype_name = prototype_name

    return self
end

return TrainPart