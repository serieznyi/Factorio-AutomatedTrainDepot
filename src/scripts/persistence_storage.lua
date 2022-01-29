local Sequence = require("scripts.lib.Sequence")

local public = {}
local private = {}

---@type scripts.lib.Sequence
local group_sequence

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@param group_id uint
---@return uint
function private.get_group_index(player, group_id)
    for i, v in pairs(global.groups[player.surface.name][player.force.name]) do
        if v.id == group_id then
            return i
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    global.sequence = {
        group = 1
    }

    group_sequence = Sequence(global.sequence.group, function(value)
        global.sequence.group = value
    end)

    global.groups = {}
end

function public.load()
    group_sequence = Sequence(global.sequence.group, function(value)
        global.sequence.group = value
    end)
end

---@param player LuaPlayer
---@param id uint
---@return atd.TrainGroup
function public.get_group(player, id)
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
---@return table set of train groups
function public.find_all(player)
    if global.groups[player.surface.name] == nil then
        return {}
    end

    return global.groups[player.surface.name][player.force.name] or {}
end

---@param player LuaPlayer
---@param train_group atd.TrainGroup
function public.add_group(player, train_group)
    if global.groups[player.surface.name] == nil then
        global.groups[player.surface.name] = {}
    end

    if global.groups[player.surface.name][player.force.name] == nil then
        global.groups[player.surface.name][player.force.name] = {}
    end

    if train_group.id == nil then
        train_group.id = group_sequence:next()
        table.insert(global.groups[player.surface.name][player.force.name], train_group)
    else
        local index = private.get_group_index(player, train_group.id)
        global.groups[player.surface.name][player.force.name][index] = train_group
    end

    return train_group
end

---@param player LuaPlayer
---@param group_id uint
function public.delete_group(player, group_id)

    if global.groups[player.surface.name] == nil or global.groups[player.surface.name][player.force.name] == nil then
        return
    end

    for i, v in pairs(global.groups[player.surface.name][player.force.name]) do
        if v.id == group_id then
            return table.remove(global.groups[player.surface.name][player.force.name], i)
        end
    end
end

return public