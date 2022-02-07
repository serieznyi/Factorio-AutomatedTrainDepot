local flib_table = require("__flib__.table")

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

--- @module scripts.lib.domain.TrainConstructTask
local public = {
    ---@type uint
    type = constants.type,
    ---@type string
    state = constants.state.created,
    ---@type bool
    deleted = false,
    ---@type string
    force_name = nil,
    ---@type string
    surface_name = nil,
    ---@type uint
    start_constructing_at = nil
}
local private = {}

public.defines = constants

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@return table
function public:to_table()
    return {
        id = self.id,
        type = self.type,
        train_template_id = self.train_template_id,
        state = self.state,
        deleted = self.deleted,
        force_name = self.force_name,
        surface_name = self.surface_name,
    }
end

---@return table
function public:delete()
    self.deleted = true
end

---@param tick uint
---@return table
function public:state_constructing(tick)
    assert(tick, "tick is nil")

    assert(self.state == constants.state.created or self.state == constants.state.paused, "wrong state")

    self.start_constructing_at = tick
end

---@param data table
---@return scripts.lib.domain.TrainConstructTask
function public.from_table(data)
    local object = public.new()

    object.id = data.id
    object.type = data.type
    object.train_template_id = data.train_template_id
    object.force_name = data.force_name
    object.surface_name = data.surface_name
    object.state = data.state
    object.deleted = data.deleted

    return object
end

---@return scripts.lib.domain.TrainConstructTask
---@param train_template scripts.lib.domain.TrainTemplate
function public.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    local task = public.new(train_template.surface_name, train_template.force_name)

    task.train_template_id = train_template.id

    return task
end

---@param surface_name string
---@param force_name string
---@return scripts.lib.domain.TrainConstructTask
function public.new(surface_name, force_name)
    ---@type scripts.lib.domain.TrainConstructTask
    local self = {}
    setmetatable(self, { __index = public })

    assert(surface_name, "surface_name is nil")
    self.surface_name = surface_name

    assert(force_name, "force_name is nil")
    self.force_name = force_name

    return self
end

return public