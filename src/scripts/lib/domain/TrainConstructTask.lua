local flib_table = require("__flib__.table")

local constants = {
    type = "construct",
    state = {
        created = "created", -- from(nil)
        forming = "forming", -- from(created, paused)
        deploying = "deploying", -- from(constructing)
        done = "done", -- from(deploying)
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
    start_forming_at = nil,
    ---@type uint
    train_template_id = nil,
    ---@type scripts.lib.domain.TrainTemplate snapshot of train template
    train_template = nil,
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
---@param multiplier double
---@param train_template scripts.lib.domain.TrainTemplate
---@return table
function public:start_forming_train(tick, multiplier, train_template)
    assert(tick, "tick is nil")

    assert(self.state == constants.state.created or self.state == constants.state.paused, "wrong state")

    self.start_forming_at = tick

    local forming_time = train_template:get_forming_time()

    self.progress_ticks = 0 -- todo calc from recipies
end

function public:progress_step()

end

function public:is_progress_done()
    return false
end

---@return bool
function public:is_state_created()
    return self.state == constants.state.created
end

---@return bool
function public:is_state_done()
    return self.state == constants.state.done
end

---@return bool
function public:is_state_paused()
    return self.state == constants.state.paused
end

---@return bool
function public:is_state_constructing()
    return self.state == constants.state.forming
end

---@return bool
function public:is_state_deploying()
    return self.state == constants.state.deploying
end

---@param data table
---@return scripts.lib.domain.TrainConstructTask
function public.from_table(data)
    local object = public.new(data.surface_name, data.force_name)

    object.id = data.id
    object.type = data.type
    object.train_template_id = data.train_template_id
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