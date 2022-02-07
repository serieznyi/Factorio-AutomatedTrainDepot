local Train = require("Train")

--- @module scripts.lib.domain.Context
local public = {
    ---@type LuaForce
    force = nil,
    ---@type string
    surface_name = nil,
    ---@type string
    force_name = nil,
}

---@param surface_name string
---@param force_name string
function public:is_same(surface_name, force_name)
    return surface_name == self.surface_name and force_name == self.force_name
end

---@param lua_entity LuaEntity
function public.from_entity(lua_entity)
    return public.new(
            nil,
            lua_entity.surface.name,
            lua_entity.force.name
    )
end

---@param entity table
function public.from_model(entity)
    return public.new(
            nil,
            entity.surface_name,
            entity.force_name
    )
end

---@param player LuaPlayer
function public.from_player(player)
    return public.new(
        player,
        player.surface.name,
        player.force.name
    )
end

---@param lua_train LuaTrain
function public.from_train(lua_train)
    local carrier = Train.get_any_carrier(lua_train)

    return public.from_entity(carrier)
end

---@param player LuaPlayer
---@param surface_name string
---@param force_name string
---@return scripts.lib.domain.Context
function public.new(player, surface_name, force_name)
    ---@type scripts.lib.domain.Context
    local self = {}
    setmetatable(self, { __index = public })

    self.player_index = player ~= nil and player.index or nil

    self.surface_name = surface_name ~= nil and surface_name or nil
    assert(self.surface_name, "surface_name is nil")

    self.force_name = force_name ~= nil and force_name or nil
    assert(self.force_name, "force_name is nil")

    return self
end

return public