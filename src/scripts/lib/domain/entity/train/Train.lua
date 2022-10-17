local flib_train = require("__flib__.train")

local constants = {
    state = {
        process_schedule = "process_schedule",
        move_to_depot = "move_to_depot",
        move_to_clean_station = "move_to_clean_station",
    }
}

--- @module scripts.lib.domain.entity.train.Train
local Train = {
    ---@type uint
    id = nil,
    ---@type uint
    train_template_id = nil,
    ---@type bool Train created for template
    controlled_train = false,
    ---@type bool
    deleted = false,
    ---@type LuaTrain
    lua_train = nil,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
    ---@type string
    state = constants.state.process_schedule,
}

---@param train_template scripts.lib.domain.entity.TrainTemplate
function Train:set_train_template(train_template)
    self.train_template_id = train_template.id
    self.controlled_train = true
end

---@return LuaEntity|nil
function Train:get_main_locomotive()
    return flib_train.get_main_locomotive(self.lua_train)
end

---@return bool
function Train:is_uncontrolled()
    return self.train_template_id == nil
end

---@param lua_train LuaTrain
function Train:set_lua_train(lua_train)
    assert(lua_train, "lua train is nil")
    assert(lua_train.valid, "lua train is invalid")

    self.lua_train = lua_train
    self.id = lua_train.id

    local locomotive = self:get_main_locomotive()

    self.force_name = locomotive.force.name
    self.surface_name = locomotive.surface.name
end

--- Mark train as deleted
function Train:delete()
    self.deleted = true
end

---@return table
function Train:to_table()
    return {
        id = self.id,
        lua_train = self.lua_train,
        surface_name = self.surface_name,
        force_name = self.force_name,
        controlled_train = self.controlled_train,
        deleted = self.deleted,
        train_template_id = self.train_template_id,
        state = self.state,
    }
end

---@param new_lua_train LuaTrain
---@return scripts.lib.domain.entity.train.Train
function Train:copy(new_lua_train)
    local copy = Train.from_lua_train(new_lua_train)

    copy.state = self.state
    copy.controlled_train = self.controlled_train
    copy.train_template_id = self.train_template_id

    return copy
end

---@param data table
function Train.from_table(data)
    local train = Train.new()

    train.id = data.id
    train.lua_train = data.lua_train
    train.force_name = data.force_name
    train.surface_name = data.surface_name
    train.controlled_train = data.controlled_train
    train.deleted = data.deleted
    train.train_template_id = data.train_template_id
    train.state = data.state

    return train
end

---@param lua_train LuaTrain
---@return scripts.lib.domain.entity.train.Train
function Train.from_lua_train(lua_train)
    local train = Train.new()

    train:set_lua_train(lua_train)

    return train
end

---@param lua_train LuaTrain
---@return LuaEntity
function Train.get_any_carrier(lua_train)
    local front_locomotive = lua_train.locomotives.front_movers[1]
    local back_locomotive = lua_train.locomotives.back_movers[1]
    local wagon = lua_train.cargo_wagons[1]

    return front_locomotive or back_locomotive or wagon
end

---@return scripts.lib.domain.entity.train.Train
function Train.new()
    ---@type scripts.lib.domain.entity.train.Train
    local self = {}
    setmetatable(self, { __index = Train })

    return self
end

return Train