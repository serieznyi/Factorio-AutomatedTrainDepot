local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------


---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

--- @module scripts.lib.domain.DepotSettings
local DepotSettings = {
    ---@type bool
    use_any_fuel = false,
    ---@type string
    force_name = nil,
    ---@type string
    default_clean_station = nil,
    ---@type string
    default_destination_station = nil,
    ---@type string
    surface_name = nil,
}

---@return table
function DepotSettings:to_table()
    return {
        use_any_fuel = self.use_any_fuel,
        default_clean_station = self.default_clean_station,
        default_destination_station = self.default_destination_station,
        force_name = self.force_name,
        surface_name = self.surface_name,
    }
end

---@param data table
function DepotSettings.from_table(data)
    local settings = DepotSettings.new()

    settings.use_any_fuel = data.use_any_fuel
    settings.default_clean_station = data.default_clean_station
    settings.default_destination_station = data.default_destination_station
    settings.force_name = data.force_name
    settings.surface_name = data.surface_name

    return settings
end

---@param context scripts.lib.domain.Context
function DepotSettings.from_context(context)
    local settings = DepotSettings.new()

    settings.force_name = context.force_name
    settings.surface_name = context.surface_name

    return settings
end

---@return scripts.lib.domain.DepotSettings
function DepotSettings.new()
    ---@type scripts.lib.domain.DepotSettings
    local self = {}
    setmetatable(self, { __index = DepotSettings })

    return self
end

return DepotSettings