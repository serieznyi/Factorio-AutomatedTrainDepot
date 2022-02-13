local flib_train = require("__flib__.train")
local flib_table = require("__flib__.table")

local Train = require("scripts.lib.domain.Train")
local Context = require("scripts.lib.domain.Context")
local TrainFormingTask = require("scripts.lib.domain.TrainFormingTask")
local persistence_storage = require("scripts.persistence_storage")
local mod_game = require("scripts.util.game")

local public = {}
local private = {}

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

---@param depot_locomotive LuaEntity
function private.ride_train(depot_locomotive)
    ---@type LuaTrain
    local train = depot_locomotive.train
    local speed = math.abs(train.speed)
    local train_driver = depot_locomotive.get_driver()
    local min_speed = 0.04
    local max_speed = min_speed + 0.02

    -- control train speed
    if speed < min_speed then
        train_driver.riding_state = {
            acceleration = defines.riding.acceleration.accelerating,
            direction = defines.riding.direction.straight,
        }
    elseif speed >= min_speed and speed <= max_speed then
        train_driver.riding_state = {
            acceleration = defines.riding.acceleration.nothing,
            direction = defines.riding.direction.straight,
        }
    elseif speed >= max_speed then
        train_driver.riding_state = {
            acceleration = defines.riding.acceleration.braking,
            direction = defines.riding.direction.straight,
        }
    end
end

---@param train_template scripts.lib.domain.TrainTemplate
---@param train LuaTrain
function private.add_train_schedule(train, train_template)
    train.schedule = {
        current = 1,
        records = {
            {station = train_template.destination_station},
        }
    }
    train.manual_mode = false
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.TrainFormingTask
---@param tick uint
function private.try_build_train(context, task, tick)
    if task:is_state_formed() then
        local train_template = persistence_storage.get_train_template(task.train_template_id)
        task:start_deploy(train_template)
        persistence_storage.trains_tasks.add(task)

        mod.log.debug("Try deploy train for template {1}", {task.train_template_id}, "depot")
    end

    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)
    ---@type LuaEntity
    local depot_station_signal = remote.call("atd", "depot_get_output_signal", context)

    if depot_station_output == nil then
        mod.log.warning("Depot station for context {1} is nil", {tostring(context)}, "depot")
    end

    local train_template = task.train_template
    local force = game.forces[task.force_name]
    local surface = game.surfaces[task.surface_name]
    local x_train, y_train = rotate_relative_position[depot_station_output.direction](-2, 3)
    local train_position = {
        x = depot_station_output.position.x + x_train,
        y = depot_station_output.position.y + y_train,
    }
    local main_locomotive = task:get_main_locomotive()
    local result_train_length = main_locomotive ~= nil and #main_locomotive.train.carriages or 0
    local target_train_length = #train_template.train

    if task:is_state_deploying() and  result_train_length ~= target_train_length then
        -- try build next train part
        
        ---@type scripts.lib.domain.TrainPart
        local train_part = train_template.train[task.deploying_cursor]

        local carrier_direction
        if train_part.direction == mod.defines.train.direction.in_direction then
            carrier_direction = depot_station_output.direction
        else
            carrier_direction = opposite[depot_station_output.direction]
        end

        local entity_data = {
            name = train_part.prototype_name,
            position = train_position,
            direction = carrier_direction,
            force = force,
        };

        if surface.can_place_entity(entity_data) then
            local carrier = surface.create_entity(entity_data)

            if train_part:is_locomotive() then
                if task.deploying_cursor == 1 then
                    private.add_train_schedule(carrier.train, train_template)

                    task:set_main_locomotive(carrier)
                end

                -- add fuel
                local inventory = carrier.get_inventory(defines.inventory.fuel)
                inventory.insert({name = "coal", count = 50})

                -- todo add inventory
            end

            private.add_train_schedule(carrier.train, train_template)

            task:deploying_cursor_next()
        end
    elseif task:is_state_deploying() and result_train_length == target_train_length then

        local cleaned_way = depot_station_signal.signal_state == defines.signal_state.open

        if cleaned_way then
            task:deployed()
            task:delete()

            main_locomotive.destroy()
        end
    end

    persistence_storage.trains_tasks.add(task)
end

function private.get_depot_multiplier()
    return 1.0 -- todo depended from technologies
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

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    return true
end

function private.get_forming_tasks_contexts()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_forming_tasks()

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in pairs(tasks) do
        table.insert(contexts, Context.from_model(task))
    end

    return contexts
end

---@param data NthTickEventData
function private.deploy_trains(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(private.get_forming_tasks_contexts()) do
        private.deploy_trains_for_context(context, data)
    end

    if persistence_storage.trains_tasks.count_forming_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(mod.defines.on_nth_tick.train_deploy, nil)
    end
end

---@param context scripts.lib.domain.Context
function private.is_deploy_slot_empty(context)
    return persistence_storage.trains_tasks.count_deploying_tasks(context) == 0
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.TrainFormingTask
---@param tick uint
function private.deploy_task(context, task, tick)
    if not task:is_state_deploying() and not task:is_state_formed() then
        return
    end

    if task:is_state_formed() and not private.is_deploy_slot_empty(context) then
        return
    end

    private.try_build_train(context, task, tick)
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function private.deploy_trains_for_context(context, data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_forming_tasks_ready_for_deploy(context)

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in pairs(tasks) do
        private.deploy_task(context, task, tick)
    end
end

---@param data NthTickEventData
function private.process_queue(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_forming_tasks()

    -- todo not process task if depot not exists

    for _, task in pairs(tasks) do
        private.process_task(task, tick)

        if task:is_state_formed() then
            script.on_nth_tick(mod.defines.on_nth_tick.train_deploy, private.deploy_trains)
        end
    end

    if persistence_storage.trains_tasks.total_count_forming_tasks() == 0 then
        script.on_nth_tick(mod.defines.on_nth_tick.tasks_processor, nil)
    end
end

---@param context scripts.lib.domain.Context
function private.get_used_forming_slots_count(context)
    return persistence_storage.trains_tasks.count_forming_tasks(context)
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

    persistence_storage.trains_tasks.add(forming_task)

    mod.log.debug("Add new forming task for template `{1}`", { train_template.name}, "depot")

    return true
end

---@param task scripts.lib.domain.TrainFormingTask
function private.discard_forming_task(task)
    task:delete()

    -- todo discard reserved inventory items

    persistence_storage.trains_tasks.add(task)

    private.raise_task_changed_event(task)

    mod.log.debug("Discard train forming task for template `{1}`", { task.train_template_id}, "depot")
end

---@param train_template scripts.lib.domain.TrainTemplate
function private.try_discard_forming_train_task_for_template(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.trains_tasks.find_forming_tasks(
            context,
            train_template.id
    )

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in pairs(tasks) do
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

---@param data NthTickEventData
function private.balance_trains_count(data)
    -- todo get surface/force from tasks
    for surface_name, _ in pairs(game.surfaces) do
        for force_name, _ in pairs(game.forces) do
            local context = Context.new(nil, surface_name, force_name)

            private.balance_trains_count_for_context(context, data)
        end
    end
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function private.balance_trains_count_for_context(context, data)
    local train_templates = persistence_storage.find_enabled_train_templates(context)

    ---@param train_template scripts.lib.domain.TrainTemplate
    for _, train_template in pairs(train_templates) do
        local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
        local forming_train_tasks = persistence_storage.trains_tasks.find_forming_tasks(context, train_template.id)
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

    if persistence_storage.trains_tasks.count_forming_tasks(context) > 0 then
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