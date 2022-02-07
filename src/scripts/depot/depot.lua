local flib_train = require("__flib__.train")
local flib_table = require("__flib__.table")

local Train = require("scripts.lib.domain.Train")
local Context = require("scripts.lib.domain.Context")
local TrainConstructTask = require("scripts.lib.domain.TrainConstructTask")
local persistence_storage = require("scripts.persistence_storage")
local mod_game = require("scripts.util.game")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param lua_train LuaTrain
---@param old_train_id_1 uint
---@param old_train_id_2 uint
function private.register_train(lua_train, old_train_id_1, old_train_id_2)
    local train_has_locomotive = flib_train.get_main_locomotive(lua_train) ~= nil
    local create_new_locomotive = old_train_id_1 == nil and old_train_id_2 == nil and train_has_locomotive
    local change_exists_train = old_train_id_1 ~= nil and old_train_id_2 == nil
    local merge_exists_train = old_train_id_1 ~= nil and old_train_id_2 ~= nil

    if not train_has_locomotive then
        mod.log.debug("Ignore train without locomotive: Train id {1}", {lua_train.id}, "depot.register_train")
        return
    end

    if create_new_locomotive then
        ---@type scripts.lib.domain.Train
        local train = Train.from_lua_train(lua_train)

        mod.log.debug("Try register new train {1}", {train.id}, "depot.register_train")

        return persistence_storage.add_train(train)
    elseif change_exists_train then
        local old_train_entity = persistence_storage.get_train(old_train_id_1)

        local new_train_entity = old_train_entity:copy(lua_train)

        old_train_entity:delete()
        persistence_storage.add_train(old_train_entity)
        mod.log.debug("Train {1} mark as deleted", {old_train_id_1}, "depot.register_train")

        mod.log.debug(
                "Try register new train {1} extended from {2}",
                {new_train_entity.id, old_train_id_1},
                "depot.register_train"
        )

        return persistence_storage.add_train(new_train_entity)
    elseif merge_exists_train then
        local newest_train_id = math.max(old_train_id_1, old_train_id_2);
        local newest_train = persistence_storage.get_train(newest_train_id);

        if newest_train ~= nil then
            newest_train:delete()
            persistence_storage.add_train(newest_train)
            mod.log.debug("Train {1} mark as deleted", {newest_train_id}, "depot.register_train")
        end

        local oldest_train_id = math.min(old_train_id_1, old_train_id_2);
        local oldest_train = persistence_storage.get_train(oldest_train_id);

        local new_train_entity

        if oldest_train ~= nil then
            new_train_entity = oldest_train:copy(lua_train)

            oldest_train:delete()
            persistence_storage.add_train(oldest_train)
            mod.log.debug("Train {1} mark as deleted", {oldest_train_id}, "depot.register_train")
        else
            new_train_entity = Train.from_lua_train(lua_train)
        end

        mod.log.debug(
                "Try register new train {1} as merge trains {2} and {3}",
                {new_train_entity.id, old_train_id_1, old_train_id_2},
                "depot.register_train"
        )

        return persistence_storage.add_train(new_train_entity)
    end
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    public.register_trains()
end

function public.load()

end

---@param train_template_id uint
function public.enable_train_template(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)
    local context = Context.from_model(train_template)

    train_template.enabled = true

    train_template = persistence_storage.add_train_template(train_template)

    public.check_trains(context)

    return train_template
end

function public.disable_train_template(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)
    train_template.enabled = false

    train_template = persistence_storage.add_train_template(train_template)

    return train_template
end

function public.increase_trains_quantity(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)
    local context = Context.from_model(train_template)

    train_template:increase_trains_quantity()

    persistence_storage.add_train_template(train_template)

    if train_template.enabled then
        public.check_trains(context)
    end

    return train_template
end

function public.decrease_trains_quantity(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)
    local context = Context.from_model(train_template)

    train_template:decrease_trains_quantity()

    persistence_storage.add_train_template(train_template)

    if train_template.enabled then
        public.check_trains(context)
    end

    return train_template
end

---@param train_id uint
function public.delete_train(train_id)
    local train = persistence_storage.get_train(train_id)

    if train == nil then
        return
    end

    train:delete()

    persistence_storage.add_train(train)

    mod.log.debug("Train {1} mark as deleted", {train_id}, "depot.delete_train")
end

function public.register_trains()
    mod.log.info("Try register all exists trains", {}, "depot.register_trains")

    ---@param train LuaTrain
    for _, train in ipairs(mod_game.get_trains()) do
        private.register_train(train)
    end
end

---@param lua_train LuaTrain
---@param old_train_id_1 uint
---@param old_train_id_2 uint
function public.register_train(lua_train, old_train_id_1, old_train_id_2)
    private.register_train(lua_train, old_train_id_1, old_train_id_2)

    public.check_trains(Context.from_train(lua_train))
end

---@param context scripts.lib.domain.Context
function public.check_trains(context)
    local train_templates = persistence_storage.find_enabled_train_templates(context)

    ---@param t scripts.lib.domain.TrainTemplate
    for _, t in ipairs(train_templates) do
        local trains = persistence_storage.find_controlled_trains_for_template(context, t.id)
        local trains_tasks = persistence_storage.find_constructing_train_tasks_for_template(context, t.id)
        local count = #trains + #trains_tasks
        local diff = t.trains_quantity - count

        game.get_player(1).print(t.name)
        game.get_player(1).print("diff " .. diff)

        if diff ~= 0 then
            for _ = 1, diff do
                local construct_task = TrainConstructTask.from_train_template(t)

                persistence_storage.add_train_task(construct_task)

                mod.log.debug("Add new construct task for {1}", {t.name}, "depot")
            end
        end
    end
end

return public