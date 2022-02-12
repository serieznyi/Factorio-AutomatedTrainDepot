local flib_table = require("__flib__.table")

local constants = {
    type = "forming",
    state = {
        created = "created", -- from(nil)
        forming = "forming", -- from(created)
        formed = "formed", -- from(forming)
        deploying = "deploying", -- from(formed)
        done = "done", -- from(deploying)
    }
}

--- @module scripts.lib.domain.TrainFormingTask
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
    train_template_id = nil,
    ---@type scripts.lib.domain.TrainTemplate snapshot of train template
    train_template = nil,
    ---@type uint ticks needed to forming train
    required_forming_ticks = nil,
    ---@type uint ticks left to forming train
    forming_end_at = nil,
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
        required_forming_ticks = self.required_forming_ticks,
        forming_end_at = self.forming_end_at,
    }
end

---@return table
function public:delete()
    self.deleted = true
end

---@return table
function public:state_formed()
    self.state = constants.state.formed
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.TrainTemplate
---@return table
function public:start_forming_train(tick, multiplier, train_template)
    assert(tick, "tick is nil")

    assert(self.state == constants.state.created or self.state == constants.state.paused, "wrong state")

    self.state = constants.state.forming

    self.required_forming_ticks = train_template:get_forming_time() * 60 * multiplier

    self.forming_end_at = tick + self.required_forming_ticks
end

---@type uint progress in percent
function public:progress()
    if self.state == constants.state.created then
        return 0
    end

    local left_ticks = self.forming_end_at - game.tick
    local diff = self.required_forming_ticks - left_ticks

    return (diff * 100) / self.required_forming_ticks
end

---@param tick uint
function public:is_forming_time_left(tick)
    return tick > self.forming_end_at
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
function public:is_state_formed()
    return self.state == constants.state.formed
end

---@return bool
function public:is_state_forming()
    return self.state == constants.state.forming
end

---@return bool
function public:is_state_deploying()
    return self.state == constants.state.deploying
end

---@param data table|scripts.lib.domain.TrainFormingTask
---@return scripts.lib.domain.TrainFormingTask
function public.from_table(data)
    local object = public.new(data.surface_name, data.force_name)

    object.id = data.id
    object.type = data.type
    object.train_template_id = data.train_template_id
    object.train_template = data.train_template
    object.state = data.state
    object.deleted = data.deleted
    object.required_forming_ticks = data.required_forming_ticks
    object.forming_end_at = data.forming_end_at

    return object
end

---@return scripts.lib.domain.TrainFormingTask
---@param train_template scripts.lib.domain.TrainTemplate
function public.from_train_template(train_template)
    assert(train_template, "train_template is nil")

    local task = public.new(train_template.surface_name, train_template.force_name)

    task.train_template_id = train_template.id

    return task
end

---@param surface_name string
---@param force_name string
---@return scripts.lib.domain.TrainFormingTask
function public.new(surface_name, force_name)
    ---@type scripts.lib.domain.TrainFormingTask
    local self = {}
    setmetatable(self, { __index = public })

    assert(surface_name, "surface_name is nil")
    self.surface_name = surface_name

    assert(force_name, "force_name is nil")
    self.force_name = force_name

    return self
end

return public