local util_table = require("scripts.util.table")
local flib_table = require("__flib__.table")

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
    deploy_cursor = 1,
    ---@type LuaEntity
    main_locomotive = nil,
    ---@type uint
    completed_at = nil,
}

---@return table
function TrainFormTask:to_table()
    return {
        id = self.id,
        type = self.type,
        train_template_id = self.train_template_id,
        train_template = self.train_template,
        state = self.state,
        deleted = self.deleted,
        force_name = self.force_name,
        surface_name = self.surface_name,
        required_form_ticks = self.required_form_ticks,
        form_end_at = self.form_end_at,
        deploy_cursor = self.deploy_cursor,
        main_locomotive = self.main_locomotive,
        completed_at = self.completed_at,
    }
end

---@return table
function TrainFormTask:delete()
    assert(self:can_cancel() or self.state == defines.state.completed, "cant delete ongoing task")

    self.deleted = true
end

---@return table
function TrainFormTask:state_formed()
    assert(self.state == defines.state.form, "wrong state")

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
function TrainFormTask:state_form(tick, multiplier, train_template)
    assert(tick, "tick is nil")
    assert(self.state == defines.state.created, "wrong state")

    self.state = defines.state.form
    self.required_form_ticks = train_template:get_form_time() * 60 * multiplier
    self.form_end_at = tick + self.required_form_ticks
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainFormTask:state_deploy(train_template)
    assert(self.state == defines.state.formed, "wrong state")

    self.state = defines.state.deploy
    self.train_template = assert(train_template, "train_template is empty")
end

function TrainFormTask:deploy_cursor_next()
    assert(self:is_state_deploy(), "wrong state")

    self.deploy_cursor = self.deploy_cursor + 1
end

---@param tick
function TrainFormTask:complete(tick)
    assert(self.state == defines.state.deploy, "wrong state")

    self.main_locomotive = nil
    self.state = defines.state.completed
    self.completed_at = assert(tick, "tick is empty")
end

---@type uint progress in percent
---@return {current: uint, total: uint}
function TrainFormTask:progress()
    local states = {}
    for k, _ in pairs(defines.state) do
        table.insert(states, k)
    end

    return {current = flib_table.find(states, self.state), total = #states}
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

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return scripts.lib.domain.entity.task.TrainFormTask
function TrainFormTask.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    return TrainFormTask.new(train_template.surface_name, train_template.force_name, train_template.id)
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