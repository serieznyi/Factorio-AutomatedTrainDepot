local flib_direction = require("__flib__.direction")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_table = require("scripts.util.table")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local depot_storage_service = require("scripts.lib.depot_storage_service")
local alert_service = require("scripts.lib.alert_service")
local logger = require("scripts.lib.logger")

local TrainsConstructor = {}

function TrainsConstructor.init()
    TrainsConstructor._register_event_handlers()
end

function TrainsConstructor.load()
    TrainsConstructor._register_event_handlers()
end

---@param data NthTickEventData
function TrainsConstructor._construct(data)
    ---@param context scripts.lib.domain.Context
    for _, context in ipairs(TrainsConstructor._get_contexts_from_tasks()) do
        TrainsConstructor._deploy_trains_for_context(context, data)
    end
end

-- todo duplicity
function TrainsConstructor._get_contexts_from_tasks()
    local contexts = {}
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        table.insert(contexts, Context.from_model(task))
    end

    return contexts
end

---@param context scripts.lib.domain.Context
---@param data NthTickEventData
function TrainsConstructor._deploy_trains_for_context(context, data)
    if not persistence_storage.is_depot_exists_at(context) then
        -- todo remove formed tasks if depot was destroyed and reset all finished tasks
        return
    end

    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_form_tasks_ready_for_deploy(context)

    ---@param task scripts.lib.domain.entity.task.TrainFormTask
    for _, task in pairs(tasks) do
        TrainsConstructor._try_deploy_train(context, task, tick)
    end
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function TrainsConstructor._try_deploy_train(context, task, tick)
    if task:is_state_formed() and not TrainsConstructor._is_deploy_slot_free(context) then
        return
    end

    TrainsConstructor._deploy_train(context, task, tick)
end

---@param context scripts.lib.domain.Context
---@return bool
function TrainsConstructor._is_deploy_slot_free(context)
    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)

    return depot_station_output.connected_rail.trains_in_block == 0
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return uint
function TrainsConstructor._calculate_train_template_fuel_stacks_count(template)
    local quantity = 0

    for _, stock in ipairs(template.train) do
        local entity_prototype = game.item_prototypes[stock.prototype_name].place_result

        if stock:is_locomotive() then
            quantity = quantity + entity_prototype.burner_prototype.fuel_inventory_size
        end
    end

    return quantity
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return uint
function TrainsConstructor._calculate_locomotives_count(template)
    local quantity = 0

    for _, stock in ipairs(template.train) do
        if stock:is_locomotive() then
            quantity = quantity + 1
        end
    end

    return quantity
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return {fuel: string, quantity: uint}[]
function TrainsConstructor._get_potential_fuel(template)
    local supported_fuel = {
        {type = "nuclear-fuel", quantity = 1}
    }

    ---@type
    for _, stock in ipairs(template.train) do
        if stock:is_locomotive() then
            local prototype = game.item_prototypes[stock.prototype_name]
        end
    end

    return supported_fuel
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return string|nil
function TrainsConstructor._get_any_fuel_type_from_depot_storage(template)
    local context = Context.from_model(template)
    local storage_entity = depot_storage_service.get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage_entity.get_inventory(defines.inventory.chest)
    local all_storage_fuels = {}

    for item, _ in pairs(inventory.get_contents()) do
        local item_prototype = game.item_prototypes[item]

        local fuel_category = item_prototype.fuel_category
        if fuel_category == "chemical" then
            table.insert(all_storage_fuels, {name = item_prototype.name, value = item_prototype.fuel_value})
        end
    end

    table.sort(all_storage_fuels, function (left, right)
        return left.value > right.value
    end)

    -- todo return only fuel which is enough
    -- todo return only fuel which can used in every train locomotive

    if #all_storage_fuels == 0 then
        return nil
    end

    return all_storage_fuels[1].name
end

--- Calculate required fuels quantity for train (one fuel stack per locomotive)
---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return table<string, uint>
function TrainsConstructor._get_train_fuel_for_reserve(template)
    local fuel_type

    if template.fuel ~= nil then
        fuel_type = template.fuel
    else
        fuel_type = TrainsConstructor._get_any_fuel_type_from_depot_storage(template)

        if not fuel_type then
            return nil
        end
    end

    local fuel_stack_size = game.item_prototypes[fuel_type].stack_size
    local locomotives_stacks_count = TrainsConstructor._calculate_locomotives_count(template)

    return {[fuel_type] = fuel_stack_size * locomotives_stacks_count}
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@return bool
function TrainsConstructor._try_reserve_train_items(context, task)
    if not depot_storage_service.can_take(context, task.train_items) then
        alert_service.add(context, atd.defines.alert_type.depot_storage_not_contains_required_items)
        return false
    end

    alert_service.remove(context, atd.defines.alert_type.depot_storage_not_contains_required_items)

    depot_storage_service.take(context, task.train_items)

    return true
end

---@param context scripts.lib.domain.Context
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return bool
function TrainsConstructor._try_reserve_train_fuel(context, train_template)
    local train_fuel = TrainsConstructor._get_train_fuel_for_reserve(train_template)
    local allow_reserve_train_fuel = train_fuel ~= nil and depot_storage_service.can_take(context, train_fuel) or false

    if not allow_reserve_train_fuel then
        alert_service.add(context, atd.defines.alert_type.depot_storage_not_contains_required_fuel)
        return false
    end

    alert_service.remove(context, atd.defines.alert_type.depot_storage_not_contains_required_fuel)

    depot_storage_service.take(context, train_fuel)

    return true
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function TrainsConstructor._deploy_train(context, task, tick)
    local task_changed = false

    if task:is_state_formed() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)

        if not TrainsConstructor._try_reserve_train_items(context, task) then
            return
        end

        if not TrainsConstructor._try_reserve_train_fuel(context, train_template) then
            return
        end

        task:state_deploy(train_template)
        task_changed = true

        logger.debug("Try deploy train for template {1}", {task.train_template_id}, "depot")
    end

    ---@type LuaEntity
    local depot_station_output = remote.call("atd", "depot_get_output_station", context)

    if depot_station_output == nil then
        logger.warning("Depot station for context {1} is nil", {tostring(context)}, "depot")
    end

    local train_template = task.train_template
    local force = game.forces[task.force_name]
    local surface = game.surfaces[task.surface_name]
    local x_train, y_train = atd.defines.rotate_relative_position[depot_station_output.direction](-2, 3)
    local train_position = {
        x = depot_station_output.position.x + x_train,
        y = depot_station_output.position.y + y_train,
    }
    local main_locomotive = task:get_main_locomotive()
    local result_train_length = main_locomotive ~= nil and #main_locomotive.train.carriages or 0
    local target_train_length = #train_template.train

    if task:is_state_deploy() and result_train_length ~= target_train_length then
        -- try build next train part

        ---@type scripts.lib.domain.entity.template.RollingStock
        local train_part = train_template.train[task.deploy_cursor]

        local carrier_direction
        if train_part.direction == atd.defines.train.direction.in_direction then
            carrier_direction = depot_station_output.direction
        else
            carrier_direction = flib_direction.opposite(depot_station_output.direction)
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
                if task.deploy_cursor == 1 then
                    task:set_main_locomotive(carrier)

                    TrainsConstructor._add_train_schedule(task.main_locomotive.train, train_template)
                end

                ---@type LuaInventory
                local inventory = carrier.get_inventory(defines.inventory.fuel)
                --local fuel_type = TrainsConstructor._get_train_for_template(train_template)
                --local fuel_item_stack_size = game.item_prototypes[template.fuel].stack_size
                --
                --inventory.insert({name = fuel_type, count = inventory.count_empty_stacks() * fuel_item_stack_size})

                inventory.insert({name = "nuclear-fuel", count = 1})
            end

            carrier.train.manual_mode = false

            task:deploy_cursor_next()

            task_changed = true
        end

    elseif task:is_state_deploy() and result_train_length == target_train_length then
        TrainsConstructor._register_train_for_template(main_locomotive.train, train_template)

        task:state_completed(tick)

        task_changed = true
    end

    if task_changed then
        persistence_storage.trains_tasks.add(task)
    end

end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param lua_train LuaTrain
function TrainsConstructor._register_train_for_template(lua_train, train_template)
    local train = persistence_storage.find_train(lua_train.id)

    train:set_train_template(train_template)

    persistence_storage.add_train(train)
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param train LuaTrain
function TrainsConstructor._add_train_schedule(train, train_template)
    train.schedule = util_table.deep_copy(train_template.destination_schedule)
    train.manual_mode = false
end

function TrainsConstructor._trains_constructor_check_activity()
    if persistence_storage.trains_tasks.count_form_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, nil)
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, TrainsConstructor._construct)
    end
end

---@param event EventData
function TrainsConstructor._handle_trains_constructor_check_activity(event)
    TrainsConstructor._trains_constructor_check_activity()
end

function TrainsConstructor._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = TrainsConstructor._handle_trains_constructor_check_activity,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "TrainsConstructor")
    end
end

return TrainsConstructor