---@class train_disband_task_defines
---@field type string
---@field state train_form_task_defines_state

---@class train_disband_task_defines_state
---@field created string
---@field try_choose_train string
---@field wait_train string
---@field disband string
---@field completed string

local defines = {
    type = "disband",
    state = {
        created = "created", -- from(nil)
        try_choose_train = "try_choose_train", -- from(created)
        wait_train = "wait_train", -- from(try_choose_train)
        disband = "disband", -- from(wait_train)
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
    ---@type uint ticks needed to forming train
    required_disband_ticks = nil,
    ---@type uint ticks left to forming train
    disband_end_at = nil,
    ---@type uint
    train_id = nil,
    ---@type uint
    train_template_id = nil,
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
        required_forming_ticks = self.required_disband_ticks,
        forming_end_at = self.disband_end_at,
        train_id = self.train_id,
        train_template_id = self.train_template_id,
    }
end

---@return table
function TrainDisbandTask:delete()
    self.deleted = true
end

function TrainDisbandTask:state_try_choose_train()
    self.state = defines.state.try_choose_train
end

function TrainDisbandTask:state_wait_train()
    self.state = defines.state.wait_train
end

function TrainDisbandTask:state_disband()
    self.state = defines.state.disband
end

function TrainDisbandTask:state_completed()
    self.state = defines.state.completed
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return table
function TrainDisbandTask:start_disband_train(tick, multiplier, train_template)
    assert(tick, "tick is nil")
    assert(multiplier, "multiplier is nil")
    assert(train_template, "train_template is nil")

    assert(self.state == defines.state.train_took, "wrong state")

    self.state = defines.state.disbanding

    self.required_disband_ticks = train_template:get_disband_time() * 60 * multiplier

    self.disband_end_at = tick + self.required_disband_ticks
end

function TrainDisbandTask:disbanded()
    self.state = defines.state.disbanded
end

---@type uint progress in percent
function TrainDisbandTask:progress()
    if self.state ~= defines.state.disbanding then
        return 0
    end

    local left_ticks = self.disband_end_at - game.tick
    local diff = self.required_disband_ticks - left_ticks

    return (diff * 100) / self.required_disband_ticks
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
    self.train_template_id = train_template_id
end

---@param data table|scripts.lib.domain.entity.task.TrainDisbandTask
---@return scripts.lib.domain.entity.task.TrainDisbandTask
function TrainDisbandTask.from_table(data)
    local object = TrainDisbandTask.new(data.surface_name, data.force_name, data.train_id)

    object.id = data.id
    object.type = data.type
    object.state = data.state
    object.deleted = data.deleted
    object.required_disband_ticks = data.required_disband_ticks
    object.disband_end_at = data.disband_end_at
    object.train_id = data.train_id
    object.train_template_id = data.train_template_id

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

    assert(surface_name, "surface_name is nil")
    self.surface_name = surface_name

    assert(force_name, "force_name is nil")
    self.force_name = force_name

    assert(train_id == nil and train_template_id == nil, "train_id and train_template_id is nil")
    self.train_id = train_id
    self.train_template_id = train_template_id

    return self
end

return TrainDisbandTask