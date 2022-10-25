local flib_table = require("__flib__.table")

local RollingStock = require("scripts.lib.domain.entity.template.RollingStock")
local util_hash = require("scripts.util.hash")
local util_table = require("scripts.util.table")

---@param lua_train LuaTrain
---@return int
function lua_train_hash_code(lua_train)
    local data = {
        color = nil,
        carriages = {},
    }

    return util_hash.hash_code(data)
end

--- @module scripts.lib.domain.entity.template.TrainTemplate
local TrainTemplate = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    ---@type string
    icon = nil,
    ---@type table
    train_color = {255, 255, 255},
    ---@type scripts.lib.domain.entity.template.RollingStock[]
    train = nil,
    ---@type bool
    enabled = nil,
    ---@type uint
    trains_quantity = nil,
    ---@type string
    clean_station = nil,
    ---@type TrainSchedule
    destination_schedule = nil,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
    ---@type string item-name
    fuel = nil,
    ---@type bool
    use_any_fuel = false,
}

---@return uint train form time in seconds (without multiplier)
function TrainTemplate:get_form_time()
    local time = 0

    ---@param rolling_stock scripts.lib.domain.entity.template.RollingStock
    for _, rolling_stock in ipairs(self.train) do
        time = time + rolling_stock:get_form_time()
    end

    return time
end

---@return uint train disband time in seconds (without multiplier)
function TrainTemplate:get_disband_time()
    local time = self:get_form_time()

    -- disband time is 85% from form time
    return math.ceil(time * 0.85)
end

---@return table
function TrainTemplate:to_table()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        train_color = self.train_color,
        ---@param rolling_stock scripts.lib.domain.entity.template.RollingStock
        train = flib_table.map(self.train or {}, function(rolling_stock)
            return rolling_stock:to_table()
        end),
        enabled = self.enabled,
        trains_quantity = self.trains_quantity,
        force_name = self.force_name,
        surface_name = self.surface_name,
        clean_station = self.clean_station,
        destination_schedule = self.destination_schedule,
        fuel = self.fuel,
        use_any_fuel = self.use_any_fuel,
    }
end

function TrainTemplate:train_structure_hash_code()
    local data = {
        color = nil,
        carriages = {},
    }

    return util_hash.hash_code(data)
end

---@param value int
function TrainTemplate:change_trains_quantity(value)
    if (self.trains_quantity + value) < 0 then
        self.trains_quantity = 0
        return
    end

    self.trains_quantity = self.trains_quantity + value
end

---@param lua_train LuaTrain
---@return int
function TrainTemplate:is_equal_train_structure(lua_train)
    return lua_train_hash_code(lua_train) == self.train_structure_hash_code()
end

function TrainTemplate:clone()
    local copy = TrainTemplate.new(nil, self.surface_name, self.force_name)

    copy.name = self.name .. " (copy)"
    copy.icon = self.icon
    copy.train_color = self.train_color
    copy.train = self.train
    copy.enabled = false
    copy.trains_quantity = self.trains_quantity
    copy.clean_station = self.clean_station
    copy.destination_schedule = self.destination_schedule
    copy.force_name = self.force_name
    copy.surface_name = self.surface_name
    copy.use_any_fuel = self.use_any_fuel
    copy.fuel = self.fuel

    return copy
end

---@param data table
function TrainTemplate.from_table(data)
    local object = TrainTemplate.new(data.id)

    util_table.fill_assoc(object, data)

    ---@param rolling_stock scripts.lib.domain.entity.template.RollingStock
    object.train = flib_table.map(data.train or {}, function(rolling_stock)
        return RollingStock.from_table(rolling_stock)
    end)

    return object
end

---@return scripts.lib.domain.entity.template.TrainTemplate
---@param context scripts.lib.domain.Context
function TrainTemplate.from_context(id, context)
    return TrainTemplate.new(id, context.surface_name, context.force_name)
end

---@param id uint
---@param surface_name string
---@param force_name string
function TrainTemplate.new(id, surface_name, force_name)
    ---@type scripts.lib.domain.entity.template.TrainTemplate
    local self = {}
    setmetatable(self, { __index = TrainTemplate })

    self.id = id
    self.surface_name = surface_name
    self.force_name = force_name

    return self
end

return TrainTemplate