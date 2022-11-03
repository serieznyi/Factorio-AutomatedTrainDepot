local logger = require("scripts.lib.logger")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")
local VirtualInventory = require("scripts.lib.VirtualInventory")
local notifier = require("scripts.lib.notifier")

local DepotStorageService = {}

---@param context scripts.lib.domain.Context
---@param train LuaEntity
---@return bool
function DepotStorageService.can_store_train(context, train)
    local items_stacks = DepotStorageService._train_to_items_stacks(train)
    local storage = DepotStorageService._get_storage(context)
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)
    local inventory_size = storage.prototype.get_inventory_size(defines.inventory.chest)
    local virtual_inventory = VirtualInventory.new(inventory_size)

    for item_name, quantity in pairs(inventory.get_contents()) do
        if not virtual_inventory:try_insert({name=item_name, count=quantity}) then
            error("Undefined error")
        end
    end

    for _, stack in ipairs(items_stacks) do
        if not virtual_inventory:try_insert(stack) then
            return false
        end
    end

    return true
end

---@return
function DepotStorageService.take_item(item_name, quantity)

end

---@param context scripts.lib.domain.Context
---@param items SimpleItemStack
function DepotStorageService.put_item(context, items)
    ---type LuaEntity
    local storage = assert(DepotStorageService._get_storage(context), 'storage is nil')
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)

    if not inventory.can_insert(items) then
        error("Can't place item in depot inventory because no free space")
    end

    inventory.insert(items)
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function DepotStorageService._get_storage(context)
    return remote.call("atd", "depot_get_storage", context)
end

function DepotStorageService._increment_items(carriage, inventory_type, counter)
    ---@type LuaInventory
    local inventory = carriage.get_inventory(inventory_type)
    if inventory ~= nil then

        for item_name, quantity in pairs(inventory.get_contents()) do
            if counter[item_name] == nil then
                counter[item_name] = quantity
            else
                counter[item_name] = counter[item_name] + quantity
            end
        end
    end
end

---@param train LuaEntity
---@return SimpleItemStack[]
function DepotStorageService._train_to_items_stacks(train)
    local train_items = {}

    ---@param carriage LuaEntity
    for _, carriage in ipairs(train.carriages) do
        -- todo not use const inside. use method arg
        if carriage.name ~= atd.defines.prototypes.entity.depot_locomotive.name then
            if train_items[carriage.name] == nil then
                train_items[carriage.name] = 1
            else
                train_items[carriage.name] = train_items[carriage.name] + train_items[carriage.name]
            end

            if carriage.type == "locomotive" then
                DepotStorageService._increment_items(carriage, defines.inventory.fuel, train_items)
            elseif carriage.type == "artillery-wagon" then
                DepotStorageService._increment_items(carriage, defines.inventory.artillery_wagon_ammo, train_items)
            elseif carriage.type == "cargo-wagon" then
                DepotStorageService._increment_items(carriage, defines.inventory.cargo_wagon, train_items)
            elseif carriage.type == "fluid-wagon" then
                -- todo place fluid in barrels
            else
                error("Unknown entity: " .. carriage.type)
            end
        end
    end

    local stacks = {}

    for name, count in pairs(train_items) do
        table.insert(stacks, {name = name, count = count})
    end

    return stacks
end

return DepotStorageService