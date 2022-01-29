local persistence_storage = require("scripts.persistence_storage")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.enable_train_group(player, group_id)
    local train_group = persistence_storage.get_group(player, group_id)

    train_group.enabled = true

    return persistence_storage.add_train_group(player, train_group)
end

function public.disable_train_group(player, group_id)
    local train_group = persistence_storage.get_group(player, group_id)

    train_group.enabled = false

    return persistence_storage.add_train_group(player, train_group)
end

return public