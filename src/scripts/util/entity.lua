local util_table = require("scripts.util.table")

local Entity = {}

---@param entity LuaEntity
function Entity.is_rolling_stock(entity)
    local types = {"locomotive", "artillery-wagon", "cargo-wagon", "fluid-wagon"}

    return util_table.find(types, entity.type) ~= nil
end

return Entity