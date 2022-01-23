local global_storage = {}

function global_storage.init()
    global.groups = {}
end

---@param player LuaPlayer
---@param index int
---@return table
function global_storage.get_group(player, index)
    return global.groups[player.surface.name][player.force.name][index]
end

---@param player LuaPlayer
---@param group_data table
function global_storage.add_group(player, group_data)
    if global.groups[player.surface.name] == nil then
        global.groups[player.surface.name] = {}
    end

    if global.groups[player.surface.name][player.force.name] == nil then
        global.groups[player.surface.name][player.force.name] = {}
    end

    table.insert(global.groups[player.surface.name][player.force.name], group_data)
end

return global_storage