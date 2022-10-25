local util_table = require("scripts.util.table")

--- @module scripts.lib.domain.entity.DepotSettings
local DepotSettings = {
    ---@type bool
    use_any_fuel = false,
    ---@type string
    fuel = nil,
    ---@type string
    force_name = nil,
    ---@type string
    default_clean_station = nil,
    ---@type string
    default_destination_schedule = nil,
    ---@type string
    surface_name = nil,
}

---@return table
function DepotSettings:to_table()
    return self
end

---@param data table
function DepotSettings.from_table(data)
    local object = DepotSettings.new()

    util_table.fill_assoc(object, data)

    return object
end

---@param context scripts.lib.domain.Context
function DepotSettings.from_context(context)
    local settings = DepotSettings.new()

    settings.force_name = context.force_name
    settings.surface_name = context.surface_name

    return settings
end

---@return scripts.lib.domain.entity.DepotSettings
function DepotSettings.new()
    ---@type scripts.lib.domain.entity.DepotSettings
    local self = {}
    setmetatable(self, { __index = DepotSettings })

    return self
end

return DepotSettings