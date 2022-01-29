local Sequence = require("scripts.lib.Sequence")

local public = {}
local private = {}

---@type scripts.lib.Sequence
local train_template_sequence

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@param train_template_id uint
---@return uint
function private.get_train_template_index(player, train_template_id)
    for i, v in pairs(global.train_templates[player.surface.name][player.force.name]) do
        if v.id == train_template_id then
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
        train_template = 1
    }

    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)

    global.train_templates = {}
end

function public.load()
    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)
end

---@param player LuaPlayer
---@param id uint
---@return atd.TrainTemplate
function public.get_train_template(player, id)
    if global.train_templates[player.surface.name] == nil or
       global.train_templates[player.surface.name][player.force.name] == nil
    then
        return nil
    end

    for _, v in pairs(global.train_templates[player.surface.name][player.force.name]) do
        if v.id == id then
            return v
        end
    end

    return nil
end

---@param player LuaPlayer
---@return table set of train templates
function public.find_all(player)
    if global.train_templates[player.surface.name] == nil then
        return {}
    end

    return global.train_templates[player.surface.name][player.force.name] or {}
end

---@param player LuaPlayer
---@param train_template atd.TrainTemplate
function public.add_train_template(player, train_template)
    if global.train_templates[player.surface.name] == nil then
        global.train_templates[player.surface.name] = {}
    end

    if global.train_templates[player.surface.name][player.force.name] == nil then
        global.train_templates[player.surface.name][player.force.name] = {}
    end

    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
        table.insert(global.train_templates[player.surface.name][player.force.name], train_template)
    else
        local index = private.get_train_template_index(player, train_template.id)
        global.train_templates[player.surface.name][player.force.name][index] = train_template
    end

    return train_template
end

---@param player LuaPlayer
---@param train_template_id uint
function public.delete_train_template(player, train_template_id)

    if global.train_templates[player.surface.name] == nil or
       global.train_templates[player.surface.name][player.force.name] == nil
    then
        return
    end

    for i, v in pairs(global.train_templates[player.surface.name][player.force.name]) do
        if v.id == train_template_id then
            return table.remove(global.train_templates[player.surface.name][player.force.name], i)
        end
    end
end

return public