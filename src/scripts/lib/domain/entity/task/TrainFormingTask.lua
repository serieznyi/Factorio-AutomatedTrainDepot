---@class train_form_task_defines
---@field type string
---@field state train_form_task_defines_state

---@class train_form_task_defines_state
---@field created string
---@field form string
---@field formed string
---@field deploy string
---@field completed string

local defines = {
    type = "forming",
    state = {
        created = "created", -- from(nil)
        form = "form", -- from(created)
        formed = "formed", -- from(form)
        deploy = "deploy", -- from(formed)
        completed = "completed", -- from(deploy)
    }
}

--- @module scripts.lib.domain.entity.task.TrainFormingTask
local TrainFormingTask = {
    ---@type train_form_task_defines
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
    ---@type uint
    train_template_id = nil,
    ---@type scripts.lib.domain.entity.template.TrainTemplate snapshot of train template
    train_template = nil,
    ---@type uint ticks needed to forming train
    required_forming_ticks = nil,
    ---@type uint ticks left to forming train
    forming_end_at = nil,
    ---@type uint
    deploying_cursor = 1,
    ---@type LuaEntity
    main_locomotive = nil,
}

---@return table
function TrainFormingTask:to_table()
    return {
        id = self.id,
        type = self.type,
        train_template_id = self.train_template_id,
        train_template = self.train_template,
        state = self.state,
        deleted = self.deleted,
        force_name = self.force_name,
        surface_name = self.surface_name,
        required_forming_ticks = self.required_forming_ticks,
        forming_end_at = self.forming_end_at,
        deploying_cursor = self.deploying_cursor,
        main_locomotive = self.main_locomotive,
    }
end

---@return table
function TrainFormingTask:delete()
    self.deleted = true
end

---@return table
function TrainFormingTask:state_formed()
    self.state = defines.state.formed
end

function TrainFormingTask:get_main_locomotive()
    if self.main_locomotive ~= nil and not self.main_locomotive.valid then
        return nil
    end

    return self.main_locomotive
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return table
function TrainFormingTask:start_forming(tick, multiplier, train_template)
    assert(tick, "tick is nil")

    assert(self.state == defines.state.created, "wrong state")

    self.state = defines.state.form

    self.required_forming_ticks = train_template:get_forming_time() * 60 * multiplier

    self.forming_end_at = tick + self.required_forming_ticks
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainFormingTask:start_deploy(train_template)
    self.state = defines.state.deploy
    self.train_template = train_template
end

function TrainFormingTask:deploying_cursor_next()
    self.deploying_cursor = self.deploying_cursor + 1
end

function TrainFormingTask:complete()
    self.main_locomotive = nil
    self.state = defines.state.completed
end

---@type uint progress in percent
---@return uint
function TrainFormingTask:progress()
    if self.state == defines.state.created then
        return 0
    end

    local left_ticks = self.forming_end_at - game.tick
    local diff = self.required_forming_ticks - left_ticks

    return (diff * 100) / self.required_forming_ticks
end

---@param entity LuaEntity
function TrainFormingTask:set_main_locomotive(entity)
    self.main_locomotive = entity
end

---@param tick uint
---@return bool
function TrainFormingTask:is_forming_time_left(tick)
    return tick > self.forming_end_at
end

---@return bool
function TrainFormingTask:is_state_created()
    return self.state == defines.state.created
end

---@return bool
function TrainFormingTask:is_state_formed()
    return self.state == defines.state.formed
end

---@return bool
function TrainFormingTask:is_state_form()
    return self.state == defines.state.form
end

---@return bool
function TrainFormingTask:can_cancel()
    return self:is_state_created() or self:is_state_form()
end

---@return bool
function TrainFormingTask:is_state_deploy()
    return self.state == defines.state.deploy
end

---@return bool
function TrainFormingTask:is_state_completed()
    return self.state == defines.state.completed
end

---@param data table|scripts.lib.domain.entity.task.TrainFormingTask
---@return scripts.lib.domain.entity.task.TrainFormingTask
function TrainFormingTask.from_table(data)
    local object = TrainFormingTask.new(data.surface_name, data.force_name, data.train_template_id)

    object.id = data.id
    object.type = data.type
    object.train_template = data.train_template
    object.main_locomotive = data.main_locomotive
    object.state = data.state
    object.deleted = data.deleted
    object.required_forming_ticks = data.required_forming_ticks
    object.forming_end_at = data.forming_end_at
    object.deploying_cursor = data.deploying_cursor

    return object
end

---@return scripts.lib.domain.entity.task.TrainFormingTask
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainFormingTask.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    local task = TrainFormingTask.new(train_template.surface_name, train_template.force_name, train_template.id)

    return task
end

---@param surface_name string
---@param force_name string
---@param train_template_id uint
---@return scripts.lib.domain.entity.task.TrainFormingTask
function TrainFormingTask.new(surface_name, force_name, train_template_id)
    ---@type scripts.lib.domain.entity.task.TrainFormingTask
    local self = {}
    setmetatable(self, { __index = TrainFormingTask })

    self.surface_name = assert(surface_name, "surface_name is nil")
    self.force_name = assert(force_name, "force_name is nil")
    self.train_template_id = assert(train_template_id, "train_template_id is nil")

    return self
end

return TrainFormingTask