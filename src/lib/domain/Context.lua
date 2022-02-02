--- @module lib.domain.Context
local public = {
    ---@type LuaForce
    force = nil,
    ---@type string
    surface_name = nil,
    ---@type string
    force_name = nil,
}

local private = {}

---@param lua_entity LuaEntity
function public.from_entity(lua_entity)
    return public.new(
            lua_entity.player,
            player.surface,
            player.force
    )
end

---@param player LuaPlayer
function public.from_player(player)
    return public.new(
        player,
        player.surface,
        player.force
    )
end

---@param player LuaPlayer
---@param lua_surface LuaSurface
---@param lua_force LuaForce
---@return lib.domain.Context
function public.new(player, lua_surface, lua_force)
    ---@type lib.domain.Context
    local self = {}
    setmetatable(self, { __index = public })

    self.player_index = player ~= nil and player.index or nil

    self.surface_name = lua_surface ~= nil and lua_surface.name or nil
    assert(self.surface_name, "surface_name is nil")

    self.force_name = lua_force ~= nil and lua_force.name or nil
    assert(self.force_name, "force_name is nil")

    return self
end

return public