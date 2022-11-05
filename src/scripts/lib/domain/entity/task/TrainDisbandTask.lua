local util_table = require("scripts.util.table")
local logger = require("scripts.lib.logger")

---@class train_disband_task_defines
---@field type string
---@field state train_disband_task_defines_state

---@class train_disband_task_defines_state
---@field created string
---@field try_choose_train string
---@field wait_train string
---@field take_apart string
---@field disband string
---@field completed string

local defines = {
    type = "disband",
    state = {
        created = "created", -- from(nil)
        try_choose_train = "try_choose_train", -- from(created)
        wait_train = "wait_train", -- from(try_choose_train)
        take_apart = "take_apart", -- from(wait_train)
        disband = "disband", -- from(take_apart)
        completed = "completed", -- from(disband)
    }
}

--- @module scripts.lib.domain.entity.task.TrainDisbandTask
local TrainDisbandTask = {
    ---@type train_disband_task_defines
    defines = defines,
    ---@type string
    type = defines.type,
    ---@type string
    state = defines.state.created,
    ---@type bool
    deleted = false,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
    ---@type uint ticks needed to disband train
    required_disband_ticks = nil,
    ---@type uint ticks left to disband train
    disband_end_at = nil,
    ---@type uint
    completed_at = nil,
    ---@type uint
    train_id = nil,
    ---@type uint
    train_template_id = nil,
    ---@type uint
    take_apart_cursor = 0,
    ---@type uint[]
    carriages_ids = {},
    ---@type table<string, uint>
    train_items = {},
}

---@return table
function TrainDisbandTask:to_table()
    return {
        id = self.id,
        type = self.type,
        state = self.state,
        deleted = self.deleted,
        force_name = self.force_name,
        surface_name = self.surface_name,
        required_disband_ticks = self.required_disband_ticks,
        disband_end_at = self.disband_end_at,
        train_id = self.train_id,
        train_template_id = self.train_template_id,
        completed_at = self.completed_at,
        take_apart_cursor = self.take_apart_cursor,
        carriages_ids = self.carriages_ids,
        train_items = self.train_items,
    }
end

---@return table
function TrainDisbandTask:delete()
    assert(self:can_cancel() or self.state == defines.state.completed, "cant delete ongoing task")

    self.deleted = true
end

function TrainDisbandTask:state_try_choose_train()
    assert(self.state == defines.state.created, "wrong state")

    self.state = defines.state.try_choose_train
end

function TrainDisbandTask:state_wait_train()
    assert(self.state == defines.state.try_choose_train, "wrong state")

    self.state = defines.state.wait_train
end

---@param train LuaTrain
---@param front_locomotive_id uint
---@param train_items table<string, uint>
function TrainDisbandTask:state_take_apart(train, front_locomotive_id, train_items)
    assert(self.state == defines.state.wait_train, "wrong state")
    assert(train, "train is nil")
    assert(train_items, "train_items is nil")
    assert(front_locomotive_id, "front_locomotive_id is nil")

    self.state = defines.state.take_apart
    self:_update_carriages_ids(train, front_locomotive_id)
    self.train_items = train_items
end

---@param train LuaTrain
---@param front_locomotive_id uint
function TrainDisbandTask:_update_carriages_ids(train, front_locomotive_id)
    assert("train", "train is nil")

    local carriages_ids = util_table.map(train.carriages, function(v) return v.unit_number end)

    if carriages_ids[1] == front_locomotive_id then
        self.carriages_ids = carriages_ids
    else
        self.carriages_ids = util_table.reverse(carriages_ids)
    end
end

---@param completed_at uint
function TrainDisbandTask:state_completed(completed_at)
    assert(self.state == defines.state.disband, "wrong state")

    self.state = defines.state.completed
    self.completed_at = assert(completed_at, "tick is empty")
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return table
function TrainDisbandTask:state_disband(tick, multiplier, train_template)
    assert(self.state == defines.state.take_apart, "wrong state")
    assert(tick, "tick is nil")
    assert(multiplier, "multiplier is nil")
    assert(train_template, "train_template is nil")

    self.state = defines.state.disband
    self.required_disband_ticks = train_template:get_disband_time() * 60 * multiplier
    self.disband_end_at = tick + self.required_disband_ticks
end

function TrainDisbandTask:take_apart_cursor_next()
    assert(self:is_state_take_apart(), "wrong state")

    self.take_apart_cursor = self.take_apart_cursor + 1
    table.remove(self.carriages_ids, 1)
end

---@return {current: uint, total: uint}
function TrainDisbandTask:progress()
    local states = {}
    for k, _ in pairs(defines.state) do
        table.insert(states, k)
    end

    return {current = util_table.find(states, self.state), total = #states}
end

---@param tick uint
function TrainDisbandTask:is_disband_time_left(tick)
    return tick > self.disband_end_at
end

---@return bool
function TrainDisbandTask:is_state_created()
    return self.state == defines.state.created
end

---@return bool
function TrainDisbandTask:is_state_try_choose_train()
    return self.state == defines.state.try_choose_train
end

---@return bool
function TrainDisbandTask:is_state_wait_train()
    return self.state == defines.state.wait_train
end

---@return bool
function TrainDisbandTask:is_state_take_apart()
    return self.state == defines.state.take_apart
end

---@return bool
function TrainDisbandTask:is_take_apart_completed()
    assert(self:is_state_take_apart(), "wrong state")

    return #self.carriages_ids == 0
end

---@return bool
function TrainDisbandTask:is_state_disband()
    return self.state == defines.state.disband
end

---@return bool
function TrainDisbandTask:is_state_completed()
    return self.state == defines.state.completed
end

---@return bool
function TrainDisbandTask:can_cancel()
    return self:is_state_created() or self:is_state_try_choose_train()
end

---@param train_template_id uint
function TrainDisbandTask:bind_with_template(train_template_id)
    self.train_template_id = assert(train_template_id, "train_template is nil")
end

---@param train LuaTrain
function TrainDisbandTask:bind_with_train(train)
    assert(train, "train is nil")
    self.train_id = train.id
end

---@param data table|scripts.lib.domain.entity.task.TrainDisbandTask
---@return scripts.lib.domain.entity.task.TrainDisbandTask
function TrainDisbandTask.from_table(data)
    local object = TrainDisbandTask.new(data.surface_name, data.force_name, data.train_id, data.train_template_id)

    util_table.fill_assoc(object, data)

    return object
end

---@param train scripts.lib.domain.entity.Train
---@return scripts.lib.domain.entity.task.TrainDisbandTask
function TrainDisbandTask.from_train(train)
    assert(train, "train is nil")

    return TrainDisbandTask.new(train.surface_name, train.force_name, train.id)
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return scripts.lib.domain.entity.task.TrainDisbandTask
function TrainDisbandTask.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    return TrainDisbandTask.new(
        train_template.surface_name,
        train_template.force_name,
        nil,
        train_template.id
    )
end

---@param surface_name string
---@param force_name string
---@param train_id uint
---@return scripts.lib.domain.entity.task.TrainDisbandTask
function TrainDisbandTask.new(surface_name, force_name, train_id, train_template_id)
    ---@type scripts.lib.domain.entity.task.TrainDisbandTask
    local self = {}
    setmetatable(self, { __index = TrainDisbandTask })

    self.surface_name = assert(surface_name, "surface_name is nil")
    self.force_name = assert(force_name, "force_name is nil")

    assert(train_id ~= nil or train_template_id ~= nil, "train_id and train_template_id is nil")
    self.train_id = train_id
    self.train_template_id = train_template_id

    return self
end

return TrainDisbandTask