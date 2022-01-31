local flib_table = require("__flib__.table")

local Train = require("lib.entity.Train")
local TrainTemplate = require("lib.entity.TrainTemplate")
local Sequence = require("lib.Sequence")

local public = {}
local private = {}

---@type lib.Sequence
local train_template_sequence

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@param train_template_id uint
---@return uint
function private.get_train_template_index(player, train_template_id)
    for i, v in pairs(global.trains_templates[player.surface.name][player.force.name]) do
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

    -- All user created templates
    global.trains_templates = {}
    global.trains = {}
end

function public.load()
    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)
end

---@param player LuaPlayer
---@param id uint
---@return lib.entity.TrainTemplate
function public.get_train_template(player, id)
    if global.trains_templates[player.surface.name] == nil or
       global.trains_templates[player.surface.name][player.force.name] == nil
    then
        return nil
    end

    for _, v in pairs(global.trains_templates[player.surface.name][player.force.name]) do
        if v.id == id then
            return TrainTemplate.from_table(v)
        end
    end

    return nil
end

---@param player LuaPlayer
---@return table set of train templates
function public.find_all_train_templates(player)
    if global.trains_templates[player.surface.name] == nil or
       global.trains_templates[player.surface.name][player.force.name] == nil
    then
        return {}
    end

    return flib_table.map(global.trains_templates[player.surface.name][player.force.name], function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param player LuaPlayer
---@param train_template lib.entity.TrainTemplate
function public.add_train_template(player, train_template)
    if global.trains_templates[player.surface.name] == nil then
        global.trains_templates[player.surface.name] = {}
    end

    if global.trains_templates[player.surface.name][player.force.name] == nil then
        global.trains_templates[player.surface.name][player.force.name] = {}
    end

    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
        table.insert(global.trains_templates[player.surface.name][player.force.name], train_template:to_table())
    else
        local index = private.get_train_template_index(player, train_template.id)
        global.trains_templates[player.surface.name][player.force.name][index] = train_template:to_table()
    end

    return train_template
end

---@param player LuaPlayer
---@param train_template_id uint
function public.delete_train_template(player, train_template_id)

    if global.trains_templates[player.surface.name] == nil or
       global.trains_templates[player.surface.name][player.force.name] == nil
    then
        return
    end

    for i, v in pairs(global.trains_templates[player.surface.name][player.force.name]) do
        if v.id == train_template_id then
            return table.remove(global.trains_templates[player.surface.name][player.force.name], i)
        end
    end
end

--- @param player LuaPlayer
--- @param train lib.entity.Train
--- @return lib.entity.Train
function public.add_train(player, train)
    ---@type LuaSurface
    local surface = player.surface
    ---@type LuaForce
    local force = player.force

    if global.trains[surface.name] == nil then
        global.trains[surface.name] = {}
    end

    if global.trains[surface.name][force.name] == nil then
        global.trains[surface.name][force.name] = {}
    end

    global.trains[surface.name][force.name][train.id] = train:to_table()

    return train
end

---@param player LuaPlayer
function public.count_uncontrolled_trains(player)
    local uncontrolled_trains = public.find_uncontrolled_trains(player)

    return #uncontrolled_trains
end

---@param player LuaPlayer
function public.find_uncontrolled_trains(player)
    if global.trains[player.surface.name] == nil or
       global.trains[player.surface.name][player.force.name] == nil
    then
        return {}
    end

    local uncontrolled_trains = flib_table.filter(
            global.trains[player.surface.name][player.force.name],
            function(t) return t.uncontrolled_train end,
            true
    )

    return flib_table.map(uncontrolled_trains, function(v)
        return Train.from_table(v)
    end)
end

---@param player LuaPlayer
---@param train_id uint
function public.get_train(player, train_id)
    if global.trains[player.surface.name] == nil or
       global.trains[player.surface.name][player.force.name] == nil
    then
        return nil
    end

    local data = global.trains[player.surface.name][player.force.name][train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(global.trains[player.surface.name][player.force.name][train_id])
end

return public