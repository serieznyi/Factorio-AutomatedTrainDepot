local flib_table = require("__flib__.table")

local logger = require("scripts.lib.logger")
local Train = require("scripts.lib.domain.Train")
local DepotSettings = require("scripts.lib.domain.DepotSettings")
local TrainTemplate = require("scripts.lib.domain.TrainTemplate")
local Sequence = require("scripts.lib.Sequence")

local garbage_collector = require("scripts.persistence.garbage_collector")
local trains_tasks = require("scripts.persistence.trains_tasks")

local public = {
    trains_tasks = trains_tasks
}
local private = {}

---@type scripts.lib.Sequence
local train_template_sequence

local gc_storage_names = { "trains", "train_template", "trains_tasks"}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param v table
---@param context scripts.lib.domain.Context
function private.match_context(v, context)
    if context == nil then
        return true
    end

    return context:is_same(v.surface_name, v.force_name)
end

---@param v table
---@param train_template_id uint
function private.match_train_template_id(v, train_template_id)
    if train_template_id == nil then
        return true
    end

    return v.train_template_id == train_template_id
end

---@param uncontrolled bool
---@param context scripts.lib.domain.Context
function private.find_trains(context, uncontrolled, train_template_id)
    local trains = flib_table.filter(global.trains, function(v)
        return v.deleted == false and
                v.uncontrolled_train == uncontrolled and
                private.match_context(v, context) and
                private.match_train_template_id(v, train_template_id)
    end, true)

    return flib_table.map(trains, Train.from_table)
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

    -- All user created templates
    global.trains_templates = {}
    global.trains = {}
    global.depot_settings = {}

    garbage_collector.init(gc_storage_names, mod.defines.persistence.garbage_ttl)

    trains_tasks.init()

    logger.debug("persistence storage was initialized")
end

function public.load()
    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)

    garbage_collector.init(gc_storage_names, mod.defines.persistence.garbage_ttl)

    trains_tasks.load()
end

-- -- -- TRAIN TEMPLATE

---@param id uint
---@return scripts.lib.domain.TrainTemplate
function public.find_train_template_by_id(id)
    local template = global.trains_templates[id]

    if template == nil then
        return nil
    end

    return TrainTemplate.from_table(template)
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.TrainTemplate[]
function public.find_train_templates_by_context(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.TrainTemplate
    local filtered = flib_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name)
    end, true)

    return flib_table.map(filtered, function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.TrainTemplate[]
function public.find_enabled_train_templates(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.TrainTemplate
    local filtered = flib_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name) and v.enabled == true
    end, true)

    return flib_table.map(filtered, function(v) return TrainTemplate.from_table(v) end)
end

---@param train_template scripts.lib.domain.TrainTemplate
---@return void
function public.add_train_template(train_template)
    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
    end

    local data = train_template:to_table()

    global.trains_templates[train_template.id] = garbage_collector.with_updated_at(data)

    return train_template
end

---@param train_template_id uint
---@return void
function public.delete_train_template(train_template_id)
    global.trains_templates[train_template_id] = nil
end

-- -- -- TRAIN

---@param train scripts.lib.domain.Train
---@return scripts.lib.domain.Train
function public.add_train(train)
    local data = train:to_table()

    global.trains[train.id] = garbage_collector.with_updated_at(data)

    return train
end

---@param context scripts.lib.domain.Context
---@return int
function public.count_uncontrolled_trains(context)
    local uncontrolled_trains = public.find_uncontrolled_trains(context)

    return #uncontrolled_trains
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.Train[]
function public.find_uncontrolled_trains(context)
    return private.find_trains(context, true)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return scripts.lib.domain.Train[]
function public.find_controlled_trains_for_template(context, train_template_id)
    return private.find_trains(context, false, train_template_id)
end

---@param train_id uint
---@return scripts.lib.domain.Train
function public.find_train(train_id)
    local data = global.trains[train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(data)
end

-- -- -- DEPOT SETTINGS

---@param settings scripts.lib.domain.DepotSettings
---@return scripts.lib.domain.DepotSettings
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

-- -- -- OTHER

---@param event NthTickEventData
function public.collect_garbage(event)
    garbage_collector.collect_garbage(event.tick)
end

return public