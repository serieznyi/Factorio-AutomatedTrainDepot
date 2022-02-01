local Train = require("lib.entity.Train")
local persistence_storage = require("scripts.persistence_storage")
local mod_game = require("scripts.util.game")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param lua_train LuaTrain
function private.register_train(lua_train)
    ---@type lib.entity.Train
    local train = persistence_storage.get_train(lua_train.id)

    if train == nil then
        train = Train.new(lua_train.id, lua_train, true)
    end

    mod.log.debug("Try register train {1}", {train.id}, "depot.register_train")

    return persistence_storage.add_train(train)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    public.register_trains()
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

function public.register_trains()
    mod.log.info("Try register all exists trains", {}, "depot.register_trains")

    ---@param train LuaTrain
    for _, train in ipairs(mod_game.get_trains()) do
        private.register_train(train)
    end
end

---@param lua_train LuaTrain
function public.register_train(lua_train)
    private.register_train(lua_train)
end

return public