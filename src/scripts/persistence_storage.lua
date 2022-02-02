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

---@param id uint
---@return lib.entity.TrainTemplate
function public.get_train_template(id)
    local template = global.trains_templates[id]

    if template == nil then
        return nil
    end

    return TrainTemplate.from_table(template)
end

---@return table set of train templates
function public.find_all_train_templates()
    local filtered = flib_table.filter(global.trains_templates, function(v)
        return v
    end)

    return flib_table.map(filtered, function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param train_template lib.entity.TrainTemplate
function public.add_train_template(train_template)
    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
    end

    global.trains_templates[train_template.id] = train_template:to_table()

    return train_template
end

---@param train_template_id uint
function public.delete_train_template(train_template_id)
    global.trains_templates[train_template_id] = nil
end

---@param train lib.entity.Train
---@return lib.entity.Train
function public.add_train(train)
    global.trains[train.id] = train:to_table()

    return train
end

function public.count_uncontrolled_trains()
    -- todo use context for get surface/force trains
    local uncontrolled_trains = public.find_uncontrolled_trains()

    return #uncontrolled_trains
end

function public.find_uncontrolled_trains()
    local uncontrolled_trains = flib_table.filter(
            global.trains,
            function(v) return v.uncontrolled_train end,
            true
    )

    return flib_table.map(uncontrolled_trains, function(v)
        return Train.from_table(v)
    end)
end

---@param train_id uint
---@return lib.entity.Train
function public.get_train(train_id)
    local train = global.trains[train_id]

    if train == nil then
        return nil
    end

    return Train.from_table(train)
end

return public