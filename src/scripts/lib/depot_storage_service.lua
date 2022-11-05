local logger = require("scripts.lib.logger")
local VirtualInventory = require("scripts.lib.VirtualInventory")

local DepotStorageService = {}

---@param context scripts.lib.domain.Context
---@param train LuaEntity
---@return bool
function DepotStorageService.can_store_train(context, train)
    local items_stacks = DepotStorageService.convert_train_to_items_stacks(train)

    return DepotStorageService.can_store(context, items_stacks)
end

---@param context scripts.lib.domain.Context
---@param items_stacks SimpleItemStack[]
---@return bool
function DepotStorageService.can_store(context, items_stacks)
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
---@param items SimpleItemStack[]
function DepotStorageService.put_items(context, items)
    assert(context, "context is nil")
    assert(items, "items is nil")

    local storage = DepotStorageService._get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)

    for _, stack in ipairs(items) do
        if not inventory.can_insert(stack) then
            -- todo not use error ?
            error("Can't place item in depot inventory because no free space")
        end

        inventory.insert(stack)
    end
end

---@param context scripts.lib.domain.Context
---@param stacks SimpleItemStack[]
function DepotStorageService.can_take(context, stacks)
    assert(context, "context is nil")
    assert(stacks, "items is nil")

    local storage = DepotStorageService._get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)
    local contents = DepotStorageService._stacks_to_contents(stacks)

    for name, quantity in pairs(contents) do
        if inventory.get_item_count(name) < quantity then
            return false
        end
    end

    return true
end

---@param context scripts.lib.domain.Context
---@param stacks SimpleItemStack[]
function DepotStorageService.take(context, stacks)
    assert(context, "context is nil")
    assert(stacks, "items is nil")

    local storage = DepotStorageService._get_storage_entity(context)
    ---@type LuaInventory
    local inventory = storage.get_inventory(defines.inventory.chest)
    local contents = DepotStorageService._stacks_to_contents(stacks)

    for name, quantity in pairs(contents) do
        inventory.remove({name = name, count = quantity})
    end
end

---@param train LuaEntity
---@return SimpleItemStack[]
function DepotStorageService.convert_train_to_items_stacks(train)
    local train_contents = {}

    ---@param carriage LuaEntity
    for _, carriage in ipairs(train.carriages) do
        local carriage_contents = DepotStorageService._get_carriage_as_contents(carriage)
        DepotStorageService._merge_contents(train_contents, carriage_contents)
    end

    return DepotStorageService._convert_contents_to_items_stacks(train_contents)
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function DepotStorageService._get_storage_entity(context)
    local storage = remote.call("atd", "depot_get_storage", context)

    return assert(storage, 'storage is nil')
end

---@param stacks SimpleItemStack[]
---@return table<string, uint>
function DepotStorageService._stacks_to_contents(stacks)
    local contents = {}

    for _, stack in ipairs(stacks) do
        if contents[stack.name] == nil then
            contents[stack.name] = 0
        end

        contents[stack.name] = contents[stack.name] + stack.count
    end

    return contents
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

return DepotStorageService