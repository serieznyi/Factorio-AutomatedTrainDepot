local util_table = require("scripts.util.table")
local atd_table = require("scripts.util.table")
local logger = require("scripts.lib.logger")
local Train = require("scripts.lib.domain.entity.Train")
local DepotSettings = require("scripts.lib.domain.entity.DepotSettings")
local TrainTemplate = require("scripts.lib.domain.entity.template.TrainTemplate")
local Sequence = require("scripts.lib.Sequence")
local Context = require("scripts.lib.domain.Context")

local garbage_collector = require("scripts.persistence.garbage_collector")

local public = {
    trains_tasks = require("scripts.persistence.trains_tasks")
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

---@param controlled bool
---@param context scripts.lib.domain.Context
function private.find_trains(context, controlled, train_template_id)
    ---@param v scripts.lib.domain.entity.Train
    local trains = util_table.filter(global.trains, function(v)
        return v.deleted == false and
                v.controlled_train == controlled and
                private.match_context(v, context) and
                private.match_train_template_id(v, train_template_id)
    end, true)

    return util_table.map(trains, Train.from_table)
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function private._raise_train_template_changed_event(train_template)
    ---@type LuaForce
    local force = game.forces[train_template.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
            atd.defines.events.on_core_train_template_changed,
            { player_index = player.index, train_template_id = train_template.id }
        )
    end
end

---@param train scripts.lib.domain.entity.Train
function private._raise_train_changed_event(train)
    ---@type LuaForce
    local force = game.forces[train.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
            atd.defines.events.on_core_train_changed,
            { player_index = player.index, train_id = train.id }
        )
    end
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
    global.depot_on_surfaces = {}

    garbage_collector.init(gc_storage_names, atd.defines.persistence.garbage_ttl)

    public.trains_tasks.init()

    logger.debug("persistence storage was initialized")
end

function public.load()
    train_template_sequence = Sequence(global.sequence.train_template, function(value)
        global.sequence.train_template = value
    end)

    garbage_collector.init(gc_storage_names, atd.defines.persistence.garbage_ttl)

    public.trains_tasks.load()
end

-- -- -- TRAIN TEMPLATE

---@param id uint
---@return scripts.lib.domain.entity.template.TrainTemplate
function public.find_train_template_by_id(id)
    local template = global.trains_templates[id]

    if template == nil then
        return nil
    end

    return TrainTemplate.from_table(template)
end

---@return scripts.lib.domain.Context[]
function public.find_contexts_from_train_templates()
    local contexts = {}

    ---@param t scripts.lib.domain.entity.template.TrainTemplate
    for _, t in ipairs(global.trains_templates) do
        table.insert(contexts, Context.new(t.surface_name, t.force_name))
    end

    return atd_table.array_unique(contexts)
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.template.TrainTemplate[]
function public.find_train_templates_by_context(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.entity.template.TrainTemplate
    local filtered = util_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name)
    end, true)

    return util_table.map(filtered, function(v)
        return TrainTemplate.from_table(v)
    end)
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.template.TrainTemplate[]
function public.find_enabled_train_templates(context)
    assert(context, "context is nil")

    ---@param v scripts.lib.domain.entity.template.TrainTemplate
    local filtered = util_table.filter(global.trains_templates, function(v)
        return context:is_same(v.surface_name, v.force_name) and v.enabled == true
    end, true)

    return util_table.map(filtered, function(v) return TrainTemplate.from_table(v) end)
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param raise_event_arg bool|nil
---@return void
function public.add_train_template(train_template, raise_event_arg)
    local raise_event = raise_event_arg ~= nil and raise_event_arg or true

    if train_template.id == nil then
        train_template.id = train_template_sequence:next()
    end

    local data = train_template:to_table()

    global.trains_templates[train_template.id] = garbage_collector.with_updated_at(data)

    if raise_event then
        private._raise_train_template_changed_event(train_template)
    end

    return train_template
end

---@param train_template_id uint
---@return void
function public.delete_train_template(train_template_id)
    global.trains_templates[train_template_id] = nil
end

---@return uint
function public.count_active_trains_templates()
    local train_templates = util_table.filter(global.trains_templates, function(v)
        return v.enabled == true
    end, true)

    return #train_templates
end

-- -- -- TRAIN

---@param train scripts.lib.domain.entity.Train
---@return scripts.lib.domain.entity.Train
function public.add_train(train)
    local data = train:to_table()

    global.trains[train.id] = garbage_collector.with_updated_at(data)

    private._raise_train_changed_event(train)

    return train
end

---@param context scripts.lib.domain.Context
---@return int
function public.count_uncontrolled_trains(context)
    local uncontrolled_trains = public.find_uncontrolled_trains(context)

    return #uncontrolled_trains
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.Train[]
function public.find_uncontrolled_trains(context)
    return private.find_trains(context, false)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return scripts.lib.domain.entity.Train[]
function public.find_controlled_trains(context, train_template_id)
    return private.find_trains(context, true, train_template_id)
end

---@param train_id uint
---@return scripts.lib.domain.entity.Train
function public.find_train(train_id)
    local data = global.trains[train_id]

    if data == nil then
        return nil
    end

    return Train.from_table(data)
end

-- -- -- DEPOT SETTINGS

---@param settings scripts.lib.domain.entity.DepotSettings
---@return scripts.lib.domain.entity.DepotSettings
function public.set_depot_settings(settings)
    if global.depot_settings[settings.surface_name] == nil then
        global.depot_settings[settings.surface_name] = {}
    end

    global.depot_settings[settings.surface_name][settings.force_name] = settings:to_table()

    return settings
end

---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.DepotSettings
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

---@param context scripts.lib.domain.Context
function public.depot_build_at(context)
    if global.depot_build_on == nil then -- todo tmp . remove later
        global.depot_build_on = {}
    end

    if global.depot_build_on[context.force_name] == nil then
        global.depot_build_on[context.force_name] = {}
    end

    global.depot_build_on[context.force_name][context.surface_name] = true
end

---@param context scripts.lib.domain.Context
function public.depot_destroyed_at(context)
    if global.depot_build_on == nil or global.depot_build_on[context.force_name] == nil then  -- todo tmp . remove later
        return
    end

    global.depot_build_on[context.force_name][context.surface_name] = nil
end

---@param context scripts.lib.domain.Context
function public.is_depot_exists_at(context)
    if global.depot_build_on == nil then -- todo tmp . remove later
        return false
    end

    return global.depot_build_on[context.force_name] ~= nil
            and global.depot_build_on[context.force_name][context.surface_name] ~= nil
end

return public