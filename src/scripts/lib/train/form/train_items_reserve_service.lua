local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local depot_storage_service = require("scripts.lib.depot_storage_service")
local alert_service = require("scripts.lib.alert_service")
local logger = require("scripts.lib.logger")
local util_table = require("scripts.util.table")

local TrainItemsReserveService = {}

---@param task scripts.lib.domain.entity.task.TrainFormTask
---@return bool
function TrainItemsReserveService.can_reserve_items(task)
    local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
    local context = Context.from_model(task)
    local check_train_items_reserve = TrainItemsReserveService.try_reserve_train_items(context, task, true)
    local check_train_fuel_reserve = TrainItemsReserveService.try_reserve_train_fuel(context, train_template, true)

    return check_train_items_reserve and check_train_fuel_reserve
end

---@param context scripts.lib.domain.Context
---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param check_only bool
---@return bool
function TrainItemsReserveService.try_reserve_train_items(context, task, check_only)
    check_only = check_only or false

    if not depot_storage_service.can_take(context, task.train_items) then
        alert_service.add(context, atd.defines.alert_type.depot_storage_not_contains_required_items)
        return false
    end

    alert_service.remove(context, atd.defines.alert_type.depot_storage_not_contains_required_items)

    if not check_only then
        depot_storage_service.take(context, task.train_items)
    end

    return true
end

---@param context scripts.lib.domain.Context
---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param check_only bool
---@return bool
function TrainItemsReserveService.try_reserve_train_fuel(context, train_template, check_only)
    check_only = check_only or false

    local train_fuel = TrainItemsReserveService._get_train_fuel_for_reserve(train_template)
    local allow_reserve_train_fuel = train_fuel ~= nil and depot_storage_service.can_take(context, train_fuel) or false

    if not allow_reserve_train_fuel then
        alert_service.add(context, atd.defines.alert_type.depot_storage_not_contains_required_fuel)
        return false
    end

    alert_service.remove(context, atd.defines.alert_type.depot_storage_not_contains_required_fuel)

    if not check_only then
        depot_storage_service.take(context, train_fuel)
    end

    return true
end

--- Calculate required fuels quantity for train (one fuel stack per locomotive)
---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return table<string, uint>
function TrainItemsReserveService._get_train_fuel_for_reserve(template)
    if template.fuel ~= nil then
        local fuel_type = template.fuel
        local fuel_stack_size = game.item_prototypes[fuel_type].stack_size
        local locomotives_count = TrainItemsReserveService._calculate_locomotives_count(template)

        return {[fuel_type] = fuel_stack_size * locomotives_count }
    end

    local context = Context.from_model(template)
    local potential_train_fuel = TrainItemsReserveService._get_potential_train_fuel(template)

    logger.debug(potential_train_fuel, {}, "potential_train_fuel")

    for _, fuel_data in pairs(potential_train_fuel) do
        if depot_storage_service.can_take(context, {[fuel_data.fuel] = fuel_data.quantity}) then
            return {[fuel_data.fuel] = fuel_data.quantity}
        end
    end

    return nil
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return {fuel: string, quantity: uint}[]
function TrainItemsReserveService._get_potential_train_fuel(template)
    local locomotives_count = TrainItemsReserveService._calculate_locomotives_count(template)
    local supported_fuels = {}

    for _, stock in ipairs(template.train) do
        if stock:is_locomotive() then
            local train_prototype = game.item_prototypes[stock.prototype_name].place_result

            for category, _ in pairs(train_prototype.burner_prototype.fuel_categories) do
                local prototypes = game.get_filtered_item_prototypes({
                    {filter="fuel-category", ["fuel-category"] = category}
                })

                for name, prototype in pairs(prototypes) do
                    supported_fuels[name] = {
                        fuel = prototype.name,
                        stack_size = prototype.stack_size,
                        fuel_value = prototype.fuel_value,
                        quantity = prototype.stack_size * locomotives_count
                    }
                end
            end

            supported_fuels = util_table.array_values(supported_fuels)

            break
        end
    end

    table.sort(supported_fuels, function (left, right)
        return left.fuel_value > right.fuel_value
    end)

    return supported_fuels
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return uint
function TrainItemsReserveService._calculate_locomotives_count(template)
    local quantity = 0

    for _, stock in ipairs(template.train) do
        if stock:is_locomotive() then
            quantity = quantity + 1
        end
    end

    return quantity
end

return TrainItemsReserveService