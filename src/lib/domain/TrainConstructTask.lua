local constants = {
    type = "construct",
    state = {
        created = "created", -- from(nil)
        wait = "wait", -- from(1)
        constructing = "constructing", -- from(1, 2, 5)
        done = "done", -- from(3)
        paused = "paused", -- from(3)
    }
}

--- @module lib.domain.TrainConstructTask
local public = {
    ---@type uint
    type = constants.type,
    ---@type lib.domain.TrainTemplate
    train_template,
    ---@type string
    state = constants.state.created,
    ---@type bool
    deleted = nil,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
}

public.defines = constants

---@return table
function public:to_table()
    return {
        type = self.type,
        train_template = self.train_template,
        force_name = self.force_name,
        surface_name = self.surface_name,
    }
end

---@return table
function public:delete()
    self.deleted = true
end

---@param data table
function public.from_table(data)
    local object = public.new()

    object.type = data.type
    object.train_template = data.train_template
    object.force_name = data.force_name
    object.surface_name = data.surface_name

    return object
end

---@return lib.domain.TrainConstructTask
---@param train_template lib.domain.TrainTemplate
function public.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    local task = public.new(train_template.surface_name, train_template.force_name)

    task.train_template = train_template

    return task
end

---@param surface_name string
---@param force_name string
---@return lib.domain.TrainConstructTask
function public.new(surface_name, force_name)
    ---@type lib.domain.TrainConstructTask
    local self = {}
    setmetatable(self, { __index = public })

    assert(surface_name, "surface_name is nil")
    self.surface_name = surface_name

    assert(force_name, "force_name is nil")
    self.force_name = force_name

    return self
end

return public