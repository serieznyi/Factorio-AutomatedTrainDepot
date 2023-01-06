local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local depot_storage_service = require("scripts.lib.depot_storage_service")
local alert_service = require("scripts.lib.alert_service")
local logger = require("scripts.lib.logger")

local TrainItemsReserveService = {}

---@param task scripts.lib.domain.entity.task.TrainFormTask
---@return bool
function TrainItemsReserveService.can_reserve_items_for_task(task)
    local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)
    local context = Context.from_model(task)

    return TrainItemsReserveService.try_reserve_train_items(context, task, true) and
            TrainItemsReserveService.try_reserve_train_fuel(context, train_template, true)
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
    local fuel_type
    local allowed_train_fuel_in_storage = TrainItemsReserveService._get_potential_fuel(template)

    logger.debug(allowed_train_fuel_in_storage, {}, "test1")

    if template.fuel ~= nil then
        fuel_type = template.fuel
    else
        fuel_type = TrainItemsReserveService._get_any_fuel_type_from_depot_storage(template)

        if not fuel_type then
            return nil
        end
    end

    local fuel_stack_size = game.item_prototypes[fuel_type].stack_size
    local locomotives_count = TrainItemsReserveService._calculate_locomotives_count(template)

    return {[fuel_type] = fuel_stack_size * locomotives_count }
end

---@param template scripts.lib.domain.entity.template.TrainTemplate
---@return {fuel: string, quantity: uint}[]
function TrainItemsReserveService._get_potential_fuel(template)
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
function TrainItemsReserveService._get_any_fuel_type_from_depot_storage(template)
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