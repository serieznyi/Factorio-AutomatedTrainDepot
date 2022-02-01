local flib_table = require("__flib__.table")

local mod_game = require("scripts.util.game")
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
    local force = player.force.name
    local surface = player.surface.name

    if global.trains_templates[surface] == nil or
       global.trains_templates[surface][force] == nil
    then
        return nil
    end

    for _, v in pairs(global.trains_templates[surface][force]) do
        if v.id == id then
            return TrainTemplate.from_table(v)
        end
    end

    return nil
end

---@param player LuaPlayer
---@return table set of train templates
function public.find_all_train_templates(player)
    local force = player.force.name
    local surface = player.surface.name

    if global.trains_templates[surface] == nil or
       global.trains_templates[surface][force] == nil
    then
        return {}
    end

    return flib_table.map(global.trains_templates[surface][force], function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param player LuaPlayer
---@param train_template lib.entity.TrainTemplate
function public.add_train_template(player, train_template)
    local force = player.force.name
    local surface = player.surface.name

    if global.trains_templates[surface] == nil then
        global.trains_templates[surface] = {}
    end

    if global.trains_templates[surface][force] == nil then
        global.trains_templates[surface][force] = {}
    end

    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
        table.insert(global.trains_templates[surface][force], train_template:to_table())
    else
        local index = private.get_train_template_index(player, train_template.id)
        global.trains_templates[surface][force][index] = train_template:to_table()
    end

    return train_template
end

---@param player LuaPlayer
---@param train_template_id uint
function public.delete_train_template(player, train_template_id)
    local force = player.force.name
    local surface = player.surface.name

    if global.trains_templates[surface] == nil or
       global.trains_templates[surface][force] == nil
    then
        return
    end

    for i, v in pairs(global.trains_templates[surface][force]) do
        if v.id == train_template_id then
            return table.remove(global.trains_templates[surface][force], i)
        end
    end
end

---@param train lib.entity.Train
---@return lib.entity.Train
function public.add_train(train)
    local surface = train:surface().name
    local force = train:force().name

    if global.trains[surface] == nil then
        global.trains[surface] = {}
    end

    if global.trains[surface][force] == nil then
        global.trains[surface][force] = {}
    end

    global.trains[surface][force][train.id] = train:to_table()

    return train
end

function public.count_uncontrolled_trains(player)
    local uncontrolled_trains = public.find_uncontrolled_trains(player)

    return #uncontrolled_trains
end

---@param player LuaPlayer
function public.find_uncontrolled_trains(player)
    local force = player.force.name
    local surface = player.surface.name

    if global.trains[surface] == nil or
       global.trains[surface][force] == nil
    then
        return {}
    end

    local uncontrolled_trains = flib_table.filter(
            global.trains[surface][force],
            function(t) return t.uncontrolled_train end,
            true
    )

    return flib_table.map(uncontrolled_trains, function(v)
        return Train.from_table(v)
    end)
end

---@param train_id uint
function public.get_train(train_id)
    local lua_train = mod_game.get_train(train_id)
    local train = Train.from_lua_train(lua_train)
    local surface = train:surface().name
    local force = train:force().name

    if global.trains[surface] == nil or
       global.trains[surface][force] == nil
    then
        return nil
    end

    local data = global.trains[surface][force][train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(global.trains[surface][force][train_id])
end

return public