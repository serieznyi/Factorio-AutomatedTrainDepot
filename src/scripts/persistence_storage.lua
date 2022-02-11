local flib_table = require("__flib__.table")

local Train = require("scripts.lib.domain.Train")
local TrainFormingTask = require("scripts.lib.domain.TrainFormingTask")
local DepotSettings = require("scripts.lib.domain.DepotSettings")
local TrainTemplate = require("scripts.lib.domain.TrainTemplate")
local Sequence = require("scripts.lib.Sequence")

local public = {}
local private = {}
local gc = {
    data = {},
}

---@type scripts.lib.Sequence
local train_template_sequence
---@type scripts.lib.Sequence
local train_task_sequence

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
    local names = {"trains", "train_template", "trains_tasks"}

    gc.init(names)

    for _, name in ipairs(names) do
        for i, v in pairs(global[name] or {}) do
            if gc.is_expired(v, tick) then
                global[name][i] = nil
                gc.increase(name)
            end
        end
    end

    gc.report()
end

---@param entry table
---@param current_tick uint
function gc.is_expired(entry, current_tick)
    local ttl = entry.updated_at + mod.defines.persistence.garbage_ttl

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

---@param uncontrolled bool
---@param context scripts.lib.domain.Context
function private.find_trains(context, uncontrolled, train_template_id)
    assert(context, "context is nil")

    local trains = flib_table.filter(global.trains, function(v)
        return v.deleted == false and
                v.uncontrolled_train == uncontrolled and
                context:is_same(v.surface_name, v.force_name) and
                (train_template_id ~= nil and v.train_template_id == train_template_id or true)
    end, true)

    return flib_table.map(trains, Train.from_table)
end

---@param context scripts.lib.domain.Context
---@param type string
---@param train_template_id uint
---@param state string
function private.find_trains_tasks(context, type, train_template_id, state)
    assert(context, "context is nil")
    assert(type, "type is nil")

    local rows = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and
                v.type == type and
                context:is_same(v.surface_name, v.force_name) and
                (train_template_id ~= nil and v.train_template_id == train_template_id or true) and
                (state ~= nil and v.state == state or true)
    end, true)

    return rows
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    global.sequence = {
        train_template = 1,
        train_task = 1,
    }

    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)
    train_task_sequence = Sequence(global.sequence.train_task, function(value)
        global.sequence.train_task = value
    end)

    -- All user created templates
    global.trains_templates = {}
    global.trains = {}
    global.depot_settings = {}
    global.trains_tasks = {}

    mod.log.debug("persistence storage was initialized")
end

function public.load()
    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)

    train_task_sequence = Sequence(global.sequence.train_task, function(value)
        global.sequence.train_task = value
    end)
end

-- -- -- TRAIN TEMPLATE

---@param id uint
---@return scripts.lib.domain.TrainTemplate
function public.get_train_template(id)
    local template = global.trains_templates[id]

    if template == nil then
        return nil
    end

    return TrainTemplate.from_table(template)
end

---@param context scripts.lib.domain.Context
---@return table set of train templates
function public.find_train_templates(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.TrainTemplate
    local filtered = flib_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name)
    end)

    return flib_table.map(filtered, function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param context scripts.lib.domain.Context
---@return table set of train templates
function public.find_enabled_train_templates(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.TrainTemplate
    local filtered = flib_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name) and v.enabled == true
    end)

    return flib_table.map(filtered, function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param train_template scripts.lib.domain.TrainTemplate
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

-- -- -- TRAIN TASK

---@param train_task scripts.lib.domain.TrainFormingTask|scripts.lib.domain.TrainDisbandTask
---@return scripts.lib.domain.TrainFormingTask|scripts.lib.domain.TrainDisbandTask
function public.add_train_task(train_task)
    if train_task.id == nil then
        train_task.id = train_task_sequence:next()
    end

    local data = train_task:to_table()

    global.trains_tasks[train_task.id] = gc.with_updated_at(data)

    -- todo remove me
    mod.log.debug(mod.util.table.to_string(global.trains_tasks[train_task.id]), {})

    script.raise_event(mod.defines.events.on_train_task_changed_mod, { train_task = train_task })

    return train_task
end

---@param train_template_id uint
---@param context scripts.lib.domain.Context
function public.find_forming_train_tasks(context, train_template_id)
    local rows = private.find_trains_tasks(
            context,
            TrainFormingTask.defines.type,
            train_template_id,
            nil
    )

    return flib_table.map(rows, TrainFormingTask.from_table)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_forming_trains_tasks(context, train_template_id)
    local tasks = public.find_forming_train_tasks(
            context,
            TrainFormingTask.defines.type,
            train_template_id,
            nil
    )

    return #tasks
end

function public.total_count_forming_train_tasks()
    local tasks = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and
                v.type == TrainFormingTask.defines.type
    end, true)

    return #tasks
end

---@return uint
function public.find_grouped_forming_train_tasks()
    local tasks = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and
               v.type == TrainFormingTask.defines.type
    end, true)

    local result = {}

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in ipairs(tasks) do
        if result[task.surface_name] == nil then
            result[task.surface_name] = {}
        end

        if result[task.surface_name][task.force_name] == nil then
            result[task.surface_name][task.force_name] = {}
        end

        if result[task.surface_name][task.force_name][task.train_template_id] == nil then
            result[task.surface_name][task.force_name][task.train_template_id] = {}
        end

        table.insert(
                result[task.surface_name][task.force_name][task.train_template_id],
                TrainFormingTask.from_table(task)
        )
    end

    return result
end

-- -- -- TRAIN

---@param train scripts.lib.domain.Train
---@return scripts.lib.domain.Train
function public.add_train(train)
    local data = train:to_table()

    global.trains[train.id] = gc.with_updated_at(data)

    return train
end

---@param context scripts.lib.domain.Context
function public.count_uncontrolled_trains(context)
    local uncontrolled_trains = public.find_uncontrolled_trains(context)

    return #uncontrolled_trains
end

---@param context scripts.lib.domain.Context
function public.find_uncontrolled_trains(context)
    return private.find_trains(context, true)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
function public.find_controlled_trains_for_template(context, train_template_id)
    return private.find_trains(context, false, train_template_id)
end

---@param train_id uint
---@return scripts.lib.domain.Train
function public.get_train(train_id)
    local data = global.trains[train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(data)
end

-- -- -- OTHER

---@param settings scripts.lib.domain.DepotSettings
function public.set_depot_settings(settings)
    if global.depot_settings[settings.surface_name] == nil then
        global.depot_settings[settings.surface_name] = {}
    end

    global.depot_settings[settings.surface_name][settings.force_name] = settings:to_table()

    return settings
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.DepotSettings
function public.get_depot_settings(context)
    if global.depot_settings[context.surface_name] == nil then
        return nil
    end

    local settings = global.depot_settings[context.surface_name][context.force_name]

    return settings and DepotSettings.from_table(settings) or nil
end

---@param event NthTickEventData
function public.collect_garbage(event)
    gc.collect_garbage(event.tick)
end

return public