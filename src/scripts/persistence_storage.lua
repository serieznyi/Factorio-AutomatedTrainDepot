local flib_table = require("__flib__.table")

local Train = require("lib.domain.Train")
local TrainTemplate = require("lib.domain.TrainTemplate")
local Sequence = require("lib.Sequence")

local public = {}
local private = {}
local gc = {
    data = {},
}

---@type lib.Sequence
local train_template_sequence

---------------------------------------------------------------------------
-- -- -- PRIVATE - GC
---------------------------------------------------------------------------

function gc.increase(name)
    gc.data[name] = gc.data[name] + 1
end

function gc.reset()
    for i, _ in pairs(gc.data) do
        gc.data[i] = 0
    end
end

---@param names table
function gc.init(names)
    for _, v in ipairs(names) do
        gc.data[v] = 0
    end
end

function gc.count()
    local count = 0

    for _, v in pairs(gc.data) do
        count = count + v
    end

    return count
end

function gc.report()
    if gc.count() > 0 then
        for name, v in pairs(gc.data) do
            mod.log.debug("Remove entries: {1} {2}", {name, v}, "persistence_storage.gc")
        end

        gc.reset()
    end
end

---@param tick uint
function gc.collect_garbage(tick)
    gc.init({"trains", "train_template"})

    -- trains
    for i, v in pairs(global.trains) do
        if gc.is_expired(v, tick) then
            global.trains[i] = nil
            gc.increase("trains")
        end
    end

    -- train templates
    for i, v in pairs(global.trains_templates) do
        if gc.is_expired(v, tick) then
            global.trains_templates[i] = nil
            gc.increase("trains_templates")
        end
    end

    gc.report()
end

---@param entry table
---@param current_tick uint
function gc.is_expired(entry, current_tick)
    local ttl = entry.updated_at + mod.defines.persistence.GARBAGE_TTL

    return ttl >= current_tick and entry.deleted == true
end

---@param data table
---@return table
function gc.with_updated_at(data)
    data.updated_at = game.tick

    return data
end

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
---@return lib.domain.TrainTemplate
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

---@param train_template lib.domain.TrainTemplate
function public.add_train_template(train_template)
    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
    end

    local data = train_template:to_table()

    global.trains_templates[train_template.id] = gc.with_updated_at(data)

    return train_template
end

---@param train_template_id uint
function public.delete_train_template(train_template_id)
    global.trains_templates[train_template_id] = nil
end

---@param train lib.domain.Train
---@return lib.domain.Train
function public.add_train(train)
    local data = train:to_table()

    global.trains[train.id] = gc.with_updated_at(data)

    mod.log.debug(mod.util.table.to_string(flib_table.map(global.trains, function(t) return {
        id = t.id, deleted = t.deleted,
    } end)), {}, "trains")

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
            function(v) return v.deleted == false and v.uncontrolled_train end,
            true
    )

    return flib_table.map(uncontrolled_trains, function(v)
        return Train.from_table(v)
    end)
end

---@param train_id uint
---@return lib.domain.Train
function public.get_train(train_id)
    local data = global.trains[train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(data)
end

---@param event NthTickEventData
function public.collect_garbage(event)
    gc.collect_garbage(event.tick)
end

return public