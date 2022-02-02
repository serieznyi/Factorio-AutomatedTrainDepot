local flib_train = require("__flib__.train")

local private = {}

local STATE = {
    EXISTS = 1,
    DELETED = 2,
}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param lua_train LuaTrain
---@return LuaEntity
function private.get_any_entity(lua_train)
    local front_locomotive = lua_train.locomotives.front_movers[1]
    local back_locomotive = lua_train.locomotives.back_movers[1]
    local wagon = lua_train.cargo_wagons[1]

    return front_locomotive or back_locomotive or wagon
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

--- @module lib.entity.Train
local Train = {
    ---@type uint
    id = nil,
    ---@type uint
    train_template_id = nil,
    ---@type bool
    uncontrolled_train = true,
    ---@type uint
    state = STATE.EXISTS,
    ---@type LuaTrain
    lua_train = nil,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
}

---@return LuaEntity
function Train:get_main_locomotive()
    return flib_train. get_main_locomotive(self.lua_train)
end

---@return LuaForce
function Train:force()
    return self:get_main_locomotive().force
end

---@return LuaSurface
function Train:surface()
    return self:get_main_locomotive().surface
end

--- Mark train as deleted
function Train:delete()
    self.state = STATE.DELETED
end

---@return table
function Train:to_table()
    return {
        id = self.id,
        lua_train = self.lua_train,
        uncontrolled_train = self.uncontrolled_train,
        state = self.state,
        train_template_id = self.train_template_id,
        surface_name = self:surface().name,
        force_name = self:force().name,
    }
end

---@param new_lua_train LuaTrain
---@return lib.entity.Train
function Train:copy(new_lua_train)
    local copy = Train.from_lua_train(new_lua_train)

    copy.state = self.state
    copy.uncontrolled_train = self.uncontrolled_train
    copy.train_template_id = self.train_template_id

    return copy
end

---@param data table
function Train.from_table(data)
    local train = Train.from_lua_train(data.lua_train)

    train.uncontrolled_train = data.uncontrolled_train
    train.state = data.state
    train.train_template_id = data.train_template_id

    return train
end

---@param lua_train LuaTrain
---@return lib.entity.Train
function Train.from_lua_train(lua_train)
    return Train.new(lua_train)
end

---@param lua_train LuaEntity
---@param uncontrolled_train bool
---@return lib.entity.Train
function Train.new(lua_train, uncontrolled_train)
    ---@type lib.entity.Train
    local self = {}
    setmetatable(self, { __index = Train })

    self.id = lua_train.id
    self.lua_train = lua_train
    self.uncontrolled_train = uncontrolled_train
    self.state = state
    self.train_template_id = train_template_id
    self.force_name = self:force().name
    self.surface_name = self:surface().name

    return self
end

return Train