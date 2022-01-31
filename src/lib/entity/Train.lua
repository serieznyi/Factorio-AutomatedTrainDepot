--- @module lib.entity.Train
local Train = {
    ---@type uint
    id = nil,
    ---@type uint
    train_template_id = nil,
    ---@type bool
    uncontrolled_train = nil,
    ---@type uint
    state = nil,
    ---@type LuaTrain
    lua_train = nil,
}

---@return LuaEntity
function Train:get_main_locomotive()
    return self.lua_train.locomotives.front_movers[1]
end

---@return table
function Train:to_table()
    return {
        id = self.id,
        lua_train = self.lua_train,
        uncontrolled_train = self.uncontrolled_train,
        state = self.state,
        train_template_id = self.train_template_id,
    }
end

---@param data table
function Train.from_table(data)
    return Train.new(
            data.id,
            data.lua_train,
            data.uncontrolled_train,
            data.state,
            data.train_template_id
    )
end

---@param lua_train LuaEntity
---@param id uint
---@param train_template_id uint
---@param uncontrolled_train bool
---@return lib.entity.Train
function Train.new(id, lua_train, uncontrolled_train, state, train_template_id)
    ---@type lib.entity.Train
    local self = {}
    setmetatable(self, { __index = Train })

    self.id = id
    self.lua_train = lua_train
    self.uncontrolled_train = uncontrolled_train
    self.state = state
    self.train_template_id = train_template_id

    return self
end

return Train