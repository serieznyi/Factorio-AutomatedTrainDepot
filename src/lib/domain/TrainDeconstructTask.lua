local constants = {
    type = "deconstruct",
    state = {
        created = "created", -- from(nil)
        deconstructing = "deconstructing", -- from(1, 4)
        done = "done", -- from(2)
        paused = "paused", -- from(2)
    }
}

--- @module lib.domain.TrainDeconstructTask
local public = {
    ---@type string
    type = constants.type,
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
    object.force_name = data.force_name
    object.surface_name = data.surface_name

    return object
end

---@return lib.domain.TrainConstructTask
---@param context lib.domain.Context
function public.create_deconstruct(context)
    assert(context, "context is nil")

    return public.new(context.surface_name, context.force_name)
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