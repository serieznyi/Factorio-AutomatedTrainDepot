---@param obj scripts.lib.domain.Context
function to_string(obj)
    return obj.surface_name .. ":" .. obj.force_name
end

--- Context is force on surface
--- @module scripts.lib.domain.Context
local Context = {
    ---@type string
    surface_name = nil,
    ---@type string
    force_name = nil,
}

---@param surface_name string
---@param force_name string
function Context:is_same(surface_name, force_name)
    assert(surface_name, "surface_name is nil")
    assert(force_name, "force_name is nil")

    return surface_name == self.surface_name and force_name == self.force_name
end

---@param lua_entity LuaEntity
---@return scripts.lib.domain.Context
function Context.from_entity(lua_entity)
    return Context.new(
            lua_entity.surface.name,
            lua_entity.force.name
    )
end

---@param entity table
---@return scripts.lib.domain.Context
function Context.from_model(entity)
    return Context.new(
            entity.surface_name,
            entity.force_name
    )
end

---@param player LuaPlayer
---@return scripts.lib.domain.Context
function Context.from_player(player)
    return Context.new(
        player.surface.name,
        player.force.name
    )
end

---@type LuaForce
function Context:force()
    return game.forces[self.force_name]
end

---@type LuaSurface
function Context:surface()
    return game.surfaces[self.surface_name]
end

---@param surface_name string
---@param force_name string
---@return scripts.lib.domain.Context
function Context.new(surface_name, force_name)
    ---@type scripts.lib.domain.Context
    local self = {}
    setmetatable(self, { __index = Context, __tostring = to_string })

    self.surface_name = surface_name or nil
    assert(self.surface_name, "surface_name is nil")

    self.force_name = force_name or nil
    assert(self.force_name, "force_name is nil")

    return self
end

return Context