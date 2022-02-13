local flib_train = require("__flib__.train")
local flib_table = require("__flib__.table")

local Train = require("scripts.lib.domain.Train")
local Context = require("scripts.lib.domain.Context")
local TrainFormingTask = require("scripts.lib.domain.TrainFormingTask")
local persistence_storage = require("scripts.persistence_storage")
local mod_game = require("scripts.util.game")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param train_task scripts.lib.domain.TrainFormingTask|scripts.lib.domain.TrainDisbandTask
function private.raise_task_changed_event(train_task)
    ---@type LuaForce
    local force = game.forces[train_task.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
                mod.defines.events.on_train_task_changed_mod,
                { train_task_id = train_task.id, player_index = player.index }
        )
    end

end

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

function private.get_forming_slots_total_count()
    return 2 -- todo depend from technologies
end

function private.get_disband_slots_count()
    return 1 -- todo depend from technologies
end

---@param task scripts.lib.domain.TrainFormingTask
---@param tick uint
function private.try_build_train(task, tick)
    local context = Context.from_model(task)
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)
    local force = game.forces[task.force_name]
    local surface = game.surfaces[task.surface_name]

    local rotate_relative_position = {
        [defines.direction.north] = function(x, y)
            return x, y
        end,
        [defines.direction.east] = function(x, y)
            return y * -1, x
        end,
        [defines.direction.south] = function(x, y)
            return x * -1, y * -1
        end,
        [defines.direction.west] = function(x, y)
            return y, x * -1
        end,
    }

    local opposite = {
        [defines.direction.north] = defines.direction.south,
        [defines.direction.east] = defines.direction.west,
        [defines.direction.south] = defines.direction.north,
        [defines.direction.west] = defines.direction.east,
    }

    local station_entity = depot_station_output
    local x_train, y_train = rotate_relative_position[station_entity.direction](-2, 3)
    local train_position = {
        x = station_entity.position.x + x_train,
        y = station_entity.position.y + y_train,
    }
    --local direction = opposite[station_entity.direction]
    local direction = station_entity.direction

    local entity_data = {
        name = "locomotive",
        position = train_position,
        direction = direction,
        force = force,
    };

    if surface.can_place_entity(entity_data) then
        local locomotive = surface.create_entity(entity_data)

        local inventory = locomotive.get_inventory(defines.inventory.fuel)

        inventory.insert({
            name = "coal",
            count = 10,
        })

        local driver = surface.create_entity({
            name = "depot-train-driver",
            position = train_position,
            force = force,
        })
        locomotive.set_driver(driver)

        driver.riding_state = {
            acceleration = defines.riding.acceleration.accelerating,
            direction = defines.riding.direction.straight,
        }
    else
        player.print("cant place locomotive")
    end
end

function private.get_depot_multiplier()
    return 10.0 -- todo depended from technologies
end

---@param task scripts.lib.domain.TrainFormingTask
---@param tick uint
function private.process_task(task, tick)
    local multiplier = private.get_depot_multiplier()

    if not task:is_state_created() and not task:is_state_forming() then
        return false
    end

    if task:is_state_created() then
        local train_template = persistence_storage.get_train_template(task.train_template_id)

        task:start_forming_train(tick, multiplier, train_template)
    end

    if task:is_forming_time_left(tick) then
        task:state_formed()
    end

    persistence_storage.add_train_task(task)

    return true
end

---@param data NthTickEventData
function private.process_queue(data)
    local tick = data.tick
    local tasks = persistence_storage.find_grouped_forming_train_tasks()
    -- todo not process task if depot not exists
    for _, surface_tasks in pairs(tasks) do
        for _, force_tasks in pairs(surface_tasks) do
            for _, template_tasks in ipairs(force_tasks) do
                ---@param task scripts.lib.domain.TrainFormingTask
                for _, task in ipairs(template_tasks) do
                    if private.process_task(task, tick) then
                        private.raise_task_changed_event(task)
                    end
                end
            end
        end
    end

    if persistence_storage.total_count_forming_train_tasks() == 0 then
        script.on_nth_tick(mod.defines.on_nth_tick.tasks_processor, nil)
    end
end

---@param context scripts.lib.domain.Context
function private.get_used_forming_slots_count(context)
    return persistence_storage.count_forming_train_tasks(context)
end

---@param train_template scripts.lib.domain.TrainTemplate
function private.try_add_forming_train_task_for_template(train_template)
    -- todo balance tasks for different forces, surfaces and templates
    local forming_slots_total_count = private.get_forming_slots_total_count()
    local context = Context.from_model(train_template)
    local used_forming_slots_count = private.get_used_forming_slots_count(context)

    if used_forming_slots_count == forming_slots_total_count then
        return false
    end

    local forming_task = TrainFormingTask.from_train_template(train_template)

    persistence_storage.add_train_task(forming_task)

    mod.log.debug("Add new forming task for template `{1}`", { train_template.name}, "depot")

    return true
end

---@param task scripts.lib.domain.TrainFormingTask
function private.discard_forming_task(task)
    task:delete()

    -- todo discard reserved inventory items

    persistence_storage.add_train_task(task)

    private.raise_task_changed_event(task)

    mod.log.debug("Discard train forming task for template `{1}`", { task.train_template_id}, "depot")
end

---@param train_template scripts.lib.domain.TrainTemplate
function private.try_discard_forming_train_task_for_template(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.find_forming_train_tasks(
            context,
            train_template.id
    )

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in ipairs(tasks) do
        if task:is_state_forming() or task:is_state_created() then
            private.discard_forming_task(task)

            return true
        end
    end

    return false
end

function private.on_ntd_register_trains_count_balancer()
    script.on_nth_tick(mod.defines.on_nth_tick.balance_trains_count, private.balance_trains_count)
end

function private.on_ntd_register_queue_processor()
    script.on_nth_tick(mod.defines.on_nth_tick.tasks_processor, private.process_queue)
end

function private.balance_trains_count()
    for surface_name, _ in pairs(game.surfaces) do
        for force_name, _ in pairs(game.forces) do
            local context = Context.new(nil, surface_name, force_name)

            private.balance_trains_count_for_context(context)
        end
    end
end

---@param context scripts.lib.domain.Context
function private.balance_trains_count_for_context(context)
    local train_templates = persistence_storage.find_enabled_train_templates(context)

    ---@param train_template scripts.lib.domain.TrainTemplate
    for _, train_template in ipairs(train_templates) do
        local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
        local forming_train_tasks = persistence_storage.find_forming_train_tasks(context, train_template.id)
        local count = #trains + #forming_train_tasks
        local diff = train_template.trains_quantity - count

        if diff > 0 then
            for _ = 1, diff do
                if not private.try_add_forming_train_task_for_template(train_template) then
                    break
                end
            end
        elseif diff < 0 then
            local count_for_delete = diff * -1

            for _ = 1, count_for_delete do
                if not private.try_discard_forming_train_task_for_template(train_template) then
                    break
                end

                count_for_delete = count_for_delete - 1
            end

            if count_for_delete > 0 then
                -- todo add task for delete train
                mod.log.debug("want delete train")
            end
        end
    end

    if persistence_storage.count_forming_trains_tasks(context) > 0 then
        private.on_ntd_register_queue_processor()
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

    train_template.enabled = true

    train_template = persistence_storage.add_train_template(train_template)

    private.on_ntd_register_trains_count_balancer()

    return train_template
end

function public.disable_train_template(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)
    train_template.enabled = false

    train_template = persistence_storage.add_train_template(train_template)

    return train_template
end

---@param train_template_id uint
---@param count int
function public.change_trains_quantity(train_template_id, count)
    local train_template = persistence_storage.get_train_template(train_template_id)
    local context = Context.from_model(train_template)

    train_template:change_trains_quantity(count)
    persistence_storage.add_train_template(train_template)

    if train_template.enabled then
        private.on_ntd_register_trains_count_balancer()
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

    private.on_ntd_register_trains_count_balancer()
end

return public