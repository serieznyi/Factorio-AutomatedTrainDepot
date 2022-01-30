--- @module lib.entity.Train
local Train = {
    ---@type uint
    id = nil,
    ---@type uint
    trainTemplateId = nil,
    ---@type bool
    uncontrolledTrain = nil,
    ---@type uint
    state = nil,
    ---@type LuaTrain
    luaTrain = nil,
}

---@return LuaEntity
function Train:getMainLocomotive()
    return self.luaTrain.locomotives.front_movers[1]
end

---@return table
function Train:toTable()
    return {
        id = self.id,
        lua_train = self.luaTrain,
        uncontrolled_train = self.uncontrolledTrain,
        state = self.state,
        train_template_id = self.trainTemplateId,
    }
end

---@param data table
function Train.fromTable(data)
    return Train.new(
            data.id,
            data.lua_train,
            data.uncontrolled_train,
            data.state,
            data.train_template_id
    )
end

---@param luaTrain LuaEntity
---@param id uint
---@param trainTemplateId uint
---@param uncontrolledTrain bool
function Train.new(id, luaTrain, uncontrolledTrain, state, trainTemplateId)
    local self = {}
    setmetatable(self, { __index = Train })

    self.id = id
    self.luaTrain = luaTrain
    self.uncontrolledTrain = uncontrolledTrain
    self.state = state
    self.trainTemplateId = trainTemplateId

    return self
end

return Train