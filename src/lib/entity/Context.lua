--- @module lib.entity.Identificator
local public = {
    ---@type LuaForce
    force = nil,
    ---@type LuaSurface
    surface = nil,
    ---@type LuaPlayer
    player = nil,
}

local private = {}

function private.not_nil(value, value_name)
    if value == nil then
        error("Value " .. value_name .. " is nil")
    end
end

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
---@return lib.entity.Identificator
function public.new(player, lua_surface, lua_force)
    ---@type lib.entity.Identificator
    local self = {}
    setmetatable(self, { __index = public })

    self.player_index = player ~= nil and player.index or nil

    self.lua_surface_name = lua_surface ~= nil and lua_surface.name or nil
    private.not_nil(self.lua_surface_name, "surface_name")

    self.lua_force_name = lua_force ~= nil and lua_force.name or nil
    private.not_nil(self.lua_surface_name, "force_name")

    return self
end

return public