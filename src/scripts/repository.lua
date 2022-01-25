local Sequence = require("scripts.lib.Sequence")

local global_storage = {}

---@type scripts.lib.Sequence
local group_sequence

function global_storage.init()
    global.sequence = {
        group = 1
    }

    group_sequence = Sequence(global.sequence.group, function(value)
        global.sequence.group = value
    end)

    global.groups = {}
end

function global_storage.load()
    group_sequence = Sequence(global.sequence.group, function(value)
        global.sequence.group = value
    end)
end

---@param player LuaPlayer
---@param id uint
---@return table
function global_storage.get_group(player, id)
    if global.groups[player.surface.name] == nil or global.groups[player.surface.name][player.force.name] == nil then
        return nil
    end

    for _, v in pairs(global.groups[player.surface.name][player.force.name]) do
        if v.id == id then
            return v
        end
    end

    return nil
end

---@param player LuaPlayer
---@return table
function global_storage.find_all(player)
    if global.groups[player.surface.name] == nil then
        return {}
    end

    return global.groups[player.surface.name][player.force.name] or {}
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

    group_data.id = group_sequence:next()

    table.insert(global.groups[player.surface.name][player.force.name], group_data)

    return group_data
end

---@param player LuaPlayer
---@param group_id uint
function global_storage.delete_group(player, group_id)

    if global.groups[player.surface.name] == nil or global.groups[player.surface.name][player.force.name] == nil then
        return
    end

    for i, v in pairs(global.groups[player.surface.name][player.force.name]) do
        if v.id == group_id then
            return table.remove(global.groups[player.surface.name][player.force.name], i)
        end
    end
end

return global_storage