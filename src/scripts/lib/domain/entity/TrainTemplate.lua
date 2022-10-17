local flib_table = require("__flib__.table")

local TrainPart = require("scripts.lib.domain.entity.train.TrainPart")
local util_hash = require("scripts.util.hash")

---@param lua_train LuaTrain
---@return int
function lua_train_hash_code(lua_train)
    local data = {
        color = nil,
        carriages = {},
    }

    return util_hash.hash_code(data)
end

--- @module scripts.lib.domain.entity.TrainTemplate
local TrainTemplate = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    ---@type string
    icon = nil,
    ---@type table
    train_color = {255, 255, 255},
    ---@type scripts.lib.domain.entity.train.TrainPart[]
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

---@return uint train forming time in seconds (without multiplier)
function TrainTemplate:get_forming_time()
    local time = 0

    ---@param part scripts.lib.domain.entity.train.TrainPart
    for _, part in ipairs(self.train) do
        time = time + part:get_forming_time()
    end

    return time
end

---@return uint train disband time in seconds (without multiplier)
function TrainTemplate:get_disband_time()
    local time = self:get_forming_time()

    -- disband time is 75% from forming time
    return math.ceil(time * 0.75)
end

---@return table
function TrainTemplate:to_table()
    return {
        id = self.id,
        name = self.name,
        icon = self.icon,
        train_color = self.train_color,
        ---@param train_part scripts.lib.domain.entity.train.TrainPart
        train = flib_table.map(self.train or {}, function(train_part)
            return train_part:to_table()
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

    object.name = data.name
    object.icon = data.icon
    object.train_color = data.train_color
    ---@param train_part scripts.lib.domain.entity.train.TrainPart
    object.train = flib_table.map(data.train or {}, function(train_part)
        return TrainPart.from_table(train_part)
    end)
    object.enabled = data.enabled
    object.trains_quantity = data.trains_quantity
    object.force_name = data.force_name
    object.surface_name = data.surface_name
    object.clean_station = data.clean_station
    object.destination_schedule = data.destination_schedule
    object.use_any_fuel = data.use_any_fuel
    object.fuel = data.fuel

    return object
end

---@return scripts.lib.domain.entity.TrainTemplate
---@param context scripts.lib.domain.Context
function TrainTemplate.from_context(id, context)
    return TrainTemplate.new(id, context.surface_name, context.force_name)
end

---@param id uint
---@param surface_name string
---@param force_name string
function TrainTemplate.new(id, surface_name, force_name)
    ---@type scripts.lib.domain.entity.TrainTemplate
    local self = {}
    setmetatable(self, { __index = TrainTemplate })

    self.id = id
    self.surface_name = surface_name
    self.force_name = force_name

    return self
end

return TrainTemplate