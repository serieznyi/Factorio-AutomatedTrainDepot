local Train = require("lib.entity.Train")
local persistence_storage = require("scripts.persistence_storage")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@param lua_train LuaTrain
function private.register_train(player, lua_train)
    ---@type lib.entity.Train
    local train = persistence_storage.get_train(player, lua_train.id)

    if train == nil then
        train = Train.new(lua_train.id, lua_train, true)
    end

    return persistence_storage.add_train(player, train)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    mod.util.logger.info("Register all exists trains")
    ---@param force LuaForce
    for force_name, force in pairs(game.forces) do
        mod.util.logger.info("Try register trains for force {1}", {force_name})

        ---@param lua_train LuaTrain
        for _, lua_train in pairs(force.get_trains()) do
            local locomotive = Train.new(0, lua_train):get_main_locomotive()
            local surface = locomotive.surface

            mod.util.logger.debug("force name: " .. tostring(force.name))
            mod.util.logger.debug("surface name" .. tostring(surface.name or nil))
            -- todo register train
        end
    end
end

function public.load()

end

function public.enable_train_template(player, train_template_id)
    local train_template = persistence_storage.get_train_template(player, train_template_id)

    train_template.enabled = true

    return persistence_storage.add_train_template(player, train_template)
end

function public.disable_train_template(player, train_template_id)
    local train_template = persistence_storage.get_train_template(player, train_template_id)

    train_template.enabled = false

    return persistence_storage.add_train_template(player, train_template)
end

---@param player LuaPlayer
function public.register_trains(player)
    ---@type LuaForce
    local force = player.force

    ---@param lua_train LuaTrain
    for _, lua_train in pairs(force.get_trains()) do
        private.register_train(player, lua_train)
    end
end

return public