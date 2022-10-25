local util_table = require("scripts.util.table")

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
    type = "form",
    state = {
        created = "created", -- from(nil)
        form = "form", -- from(created)
        formed = "formed", -- from(form)
        deploy = "deploy", -- from(formed)
        completed = "completed", -- from(deploy)
    }
}

--- @module scripts.lib.domain.entity.task.TrainFormTask
local TrainFormTask = {
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
    ---@type uint ticks needed to form train
    required_form_ticks = nil,
    ---@type uint ticks left to form train
    form_end_at = nil,
    ---@type uint
    deploying_cursor = 1,
    ---@type LuaEntity
    main_locomotive = nil,
    ---@type uint
    completed_at = nil,
}

---@return table
function TrainFormTask:to_table()
    return self
end

---@return table
function TrainFormTask:delete()
    self.deleted = true
end

---@return table
function TrainFormTask:state_formed()
    self.state = defines.state.formed
end

function TrainFormTask:get_main_locomotive()
    if self.main_locomotive ~= nil and not self.main_locomotive.valid then
        return nil
    end

    return self.main_locomotive
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return table
function TrainFormTask:start_form(tick, multiplier, train_template)
    assert(tick, "tick is nil")

    assert(self.state == defines.state.created, "wrong state")

    self.state = defines.state.form

    self.required_form_ticks = train_template:get_form_time() * 60 * multiplier

    self.form_end_at = tick + self.required_form_ticks
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainFormTask:start_deploy(train_template)
    self.state = defines.state.deploy
    self.train_template = train_template
end

function TrainFormTask:deploying_cursor_next()
    self.deploying_cursor = self.deploying_cursor + 1
end

---@param tick
function TrainFormTask:complete(tick)
    self.main_locomotive = nil
    self.state = defines.state.completed
    self.completed_at = assert(tick, "tick is empty")
end

---@type uint progress in percent
---@return uint
function TrainFormTask:progress()
    if self.state == defines.state.created then
        return 0
    end

    local left_ticks = self.form_end_at - game.tick
    local diff = self.required_form_ticks - left_ticks

    return (diff * 100) / self.required_form_ticks
end

---@param entity LuaEntity
function TrainFormTask:set_main_locomotive(entity)
    self.main_locomotive = entity
end

---@param tick uint
---@return bool
function TrainFormTask:is_form_time_left(tick)
    return tick > self.form_end_at
end

---@return bool
function TrainFormTask:is_state_created()
    return self.state == defines.state.created
end

---@return bool
function TrainFormTask:is_state_formed()
    return self.state == defines.state.formed
end

---@return bool
function TrainFormTask:is_state_form()
    return self.state == defines.state.form
end

---@return bool
function TrainFormTask:can_cancel()
    return self:is_state_created() or self:is_state_form()
end

---@return bool
function TrainFormTask:is_state_deploy()
    return self.state == defines.state.deploy
end

---@return bool
function TrainFormTask:is_state_completed()
    return self.state == defines.state.completed
end

---@param data table|scripts.lib.domain.entity.task.TrainFormTask
---@return scripts.lib.domain.entity.task.TrainFormTask
function TrainFormTask.from_table(data)
    local object = TrainFormTask.new(data.surface_name, data.force_name, data.train_template_id)

    util_table.fill_assoc(object, data)

    return object
end

---@return scripts.lib.domain.entity.task.TrainFormTask
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainFormTask.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    local task = TrainFormTask.new(train_template.surface_name, train_template.force_name, train_template.id)

    return task
end

---@param surface_name string
---@param force_name string
---@param train_template_id uint
---@return scripts.lib.domain.entity.task.TrainFormTask
function TrainFormTask.new(surface_name, force_name, train_template_id)
    ---@type scripts.lib.domain.entity.task.TrainFormTask
    local self = {}
    setmetatable(self, { __index = TrainFormTask })

    self.surface_name = assert(surface_name, "surface_name is nil")
    self.force_name = assert(force_name, "force_name is nil")
    self.train_template_id = assert(train_template_id, "train_template_id is nil")

    return self
end

return TrainFormTask