local persistence_storage = require("scripts.persistence_storage")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()

end

function public.load()

end

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

function public.register_all_unmanaged_trains(player)
    ---@type atd.TrainGroup
    local uncontrolled_trains_group = {}
    -- TODO use id = 1 or find solution for move this group in begin of list
    --uncontrolled_trains_group.id = mod.defines.train_group.default_group.id
    -- TODO add translate for group name
    uncontrolled_trains_group.name = "depot.uncontrolled-trains-group"
    uncontrolled_trains_group.enabled = false
    uncontrolled_trains_group.readonly = true
    uncontrolled_trains_group.icon = "locomotive"
    uncontrolled_trains_group.train = {}

    persistence_storage.add_train_group(player, uncontrolled_trains_group)
end

function public.register_train(train_id, group_id, state)

end

return public