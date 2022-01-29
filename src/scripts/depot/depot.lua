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

function public.register_all_unmanaged_trains(player)
    ---@type atd.TrainTemplate
    local uncontrolled_trains_group = {}
    -- TODO use id = 1 or find solution for move this train template in begin of list
    --uncontrolled_trains_group.id = mod.defines.train_group.default_group.id
    -- TODO add translate for group name
    uncontrolled_trains_group.name = "depot.uncontrolled-trains-group"
    uncontrolled_trains_group.enabled = false
    uncontrolled_trains_group.readonly = true
    uncontrolled_trains_group.icon = "locomotive"
    uncontrolled_trains_group.train = {}

    persistence_storage.add_train_template(player, uncontrolled_trains_group)
end

function public.register_train(train_id, train_template_id, state)

end

return public