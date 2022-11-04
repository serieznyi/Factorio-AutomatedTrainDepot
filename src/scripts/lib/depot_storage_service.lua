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
    local items_stacks = DepotStorageService._convert_train_to_items_stacks(train)
    local storage_entity = DepotStorageService._get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage_entity.get_inventory(defines.inventory.chest)
    local inventory_size = storage_entity.prototype.get_inventory_size(defines.inventory.chest)
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

---@param context scripts.lib.domain.Context
---@param carriage LuaEntity
function DepotStorageService.put_carriage(context, carriage)
    assert(carriage.train ~= nil, "arg is not carriage")

    if DepotStorageService._is_ignored_carriage(carriage) then
        return
    end

    local storage = DepotStorageService._get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)
    local carriage_stacks = DepotStorageService._convert_carriage_to_items_stacks(carriage)

    for _, stack in ipairs(carriage_stacks) do
        if not inventory.can_insert(stack) then
            -- todo not use error ?
            error("Can't place item in depot inventory because no free space")
        end

        inventory.insert(stack)
    end
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function DepotStorageService._get_storage_entity(context)
    local storage = remote.call("atd", "depot_get_storage", context)

    return assert(storage, 'storage is nil')
end

---@param train LuaEntity
---@return SimpleItemStack[]
function DepotStorageService._convert_train_to_items_stacks(train)
    local train_contents = {}

    ---@param carriage LuaEntity
    for _, carriage in ipairs(train.carriages) do
        if train_contents[carriage.name] == nil then
            train_contents[carriage.name] = 1
        else
            train_contents[carriage.name] = train_contents[carriage.name] + train_contents[carriage.name]
        end

        local carriage_contents = DepotStorageService._get_carriage_as_contents(carriage)
        DepotStorageService._merge_contents(train_contents, carriage_contents)

        if DepotStorageService._is_ignored_carriage(carriage) then
            train_contents[carriage.name] = nil
        end
    end

    return DepotStorageService._convert_contents_to_items_stacks(train_contents)
end

---@param carriage LuaEntity
---@return SimpleItemStack[]
function DepotStorageService._convert_carriage_to_items_stacks(carriage)
    local carriage_contents = DepotStorageService._get_carriage_as_contents(carriage)

    return DepotStorageService._convert_contents_to_items_stacks(carriage_contents)
end

---@param carriage LuaEntity
---@return SimpleItemStack[]
function DepotStorageService._get_carriage_as_contents(carriage)
    local contents = {}

    if carriage.type == "locomotive" then
        contents = carriage.get_inventory(defines.inventory.fuel).get_contents()
    elseif carriage.type == "artillery-wagon" then
        contents = carriage.get_inventory(defines.inventory.artillery_wagon_ammo).get_contents()
    elseif carriage.type == "cargo-wagon" then
        contents = carriage.get_inventory(defines.inventory.cargo_wagon).get_contents()
    elseif carriage.type == "fluid-wagon" then
        -- todo place fluid in barrels
    else
        error("Unknown entity: " .. carriage.type)
    end

    if contents[carriage.prototype.type] == nil then
        contents[carriage.prototype.type] = 0
    end

    -- Add carriage item in contents
    contents[carriage.prototype.type] = contents[carriage.prototype.type] + 1

    return contents
end

---@param contents table
---@return table
function DepotStorageService._convert_contents_to_items_stacks(contents)
    local stacks = {}

    for name, count in pairs(contents) do
        table.insert(stacks, {name = name, count = count})
    end

    return stacks
end

---@param target_table table
---@param source_table table
function DepotStorageService._merge_contents(target_table, source_table)
    for item_name, quantity in pairs(source_table) do
        if target_table[item_name] == nil then
            target_table[item_name] = quantity
        else
            target_table[item_name] = target_table[item_name] + quantity
        end
    end
end

---@param carriage LuaEntity
---@return bool
function DepotStorageService._is_ignored_carriage(carriage)
    return carriage.name == atd.defines.prototypes.entity.depot_locomotive.name
end

return DepotStorageService