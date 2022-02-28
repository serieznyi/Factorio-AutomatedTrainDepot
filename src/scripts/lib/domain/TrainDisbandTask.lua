local constants = {
    type = "disband",
    state = {
        created = "created", -- from(nil)
        train_taking = "train_taking", -- from(created)
        train_took = "train_took", -- from(train_taking)
        disbanding = "disbanding", -- from(train_took)
        disbanded = "disbanded", -- from(disbanding)
    }
}

--- @module scripts.lib.domain.TrainDisbandTask
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
    ---@type uint ticks needed to forming train
    required_disband_ticks = nil,
    ---@type uint ticks left to forming train
    disband_end_at = nil,
    ---@type uint
    train_id = nil,
}

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
        state = self.state,
        deleted = self.deleted,
        force_name = self.force_name,
        surface_name = self.surface_name,
        required_forming_ticks = self.required_disband_ticks,
        forming_end_at = self.disband_end_at,
        train_id = self.train_id,
    }
end

---@return table
function public:delete()
    self.deleted = true
end

---@return table
function public:state_disbanded()
    self.state = constants.state.disbanded
end

---@return table
function public:state_train_took()
    self.state = constants.state.train_took
end

---@param tick uint
---@param multiplier double
---@param train_template scripts.lib.domain.TrainTemplate
---@return table
function public:start_disband_train(tick, multiplier, train_template)
    assert(tick, "tick is nil")
    assert(multiplier, "multiplier is nil")
    assert(train_template, "train_template is nil")

    assert(self.state == constants.state.train_took, "wrong state")

    self.state = constants.state.disbanding

    self.required_disband_ticks = train_template:get_disband_time() * 60 * multiplier

    self.disband_end_at = tick + self.required_disband_ticks
end

function public:state_train_taking()
    self.state = constants.state.deploying
end

function public:disbanded()
    self.state = constants.state.disbanded
end

---@type uint progress in percent
function public:progress()
    if self.state ~= constants.state.disbanding then
        return 0
    end

    local left_ticks = self.disband_end_at - game.tick
    local diff = self.required_disband_ticks - left_ticks

    return (diff * 100) / self.required_disband_ticks
end

---@param tick uint
function public:is_disband_time_left(tick)
    return tick > self.disband_end_at
end

---@return bool
function public:is_state_created()
    return self.state == constants.state.created
end

---@return bool
function public:is_state_disbanded()
    return self.state == constants.state.disbanded
end

---@return bool
function public:is_state_train_taking()
    return self.state == constants.state.train_taking
end

---@return bool
function public:is_state_train_took()
    return self.state == constants.state.train_took
end

---@return bool
function public:is_state_disbanded()
    return self.state == constants.state.disbanded
end

---@param data table|scripts.lib.domain.TrainDisbandTask
---@return scripts.lib.domain.TrainDisbandTask
function public.from_table(data)
    local object = public.new(data.surface_name, data.force_name, data.train_id)

    object.id = data.id
    object.type = data.type
    object.state = data.state
    object.deleted = data.deleted
    object.required_disband_ticks = data.required_disband_ticks
    object.disband_end_at = data.disband_end_at
    object.train_id = data.train_id

    return object
end

---@return scripts.lib.domain.TrainDisbandTask
---@param train scripts.lib.domain.Train
function public.from_train(train)
    assert(train, "train is nil")

    local task = public.new(train.surface_name, train.force_name, train.id)

    return task
end

---@param surface_name string
---@param force_name string
---@param train_id uint
---@return scripts.lib.domain.TrainDisbandTask
function public.new(surface_name, force_name, train_id)
    ---@type scripts.lib.domain.TrainDisbandTask
    local self = {}
    setmetatable(self, { __index = public })

    assert(surface_name, "surface_name is nil")
    self.surface_name = surface_name

    assert(force_name, "force_name is nil")
    self.force_name = force_name

    assert(train_id, "train_id is nil")
    self.train_id = train_id

    return self
end

return public