local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local EventDispatcher = require("scripts.util.EventDispatcher")
local mod_table = require("scripts.util.table")
local validator = require("scripts.gui.validator")
local Sequence = require("scripts.lib.Sequence")
local persistence_storage = require("scripts.persistence_storage")

local component_id_sequence = Sequence()

--- @class gui.component.TrainScheduleSelector.Schedule
--- @field name string
--- @field schedule TrainSchedule

--- @module gui.component.TrainScheduleSelector
local TrainScheduleSelector = {
    ---@type uint
    id = nil,
    ---@type gui.component.TrainScheduleSelector.Schedule
    selected_schedule = nil,
    ---@type scripts.lib.domain.Context
    context = nil,
    ---@type LuaForce
    force = nil,
    ---@type LuaSurface
    surface = nil,
    ---@type table
    actions = {},
    refs = {
        ---@type LuaGuiElement
        drop_down = nil,
    },
    ---@type bool
    required = false,
    ---@type function
    on_changed = function() end,
    ---@type TrainSchedule[]
    schedules = nil,
}

---@param context scripts.lib.domain.Context
---@param on_changed function
---@param selected_schedule TrainSchedule
---@return scripts.lib.domain.Train
function TrainScheduleSelector.new(container, context, on_changed, selected_schedule, required)
    ---@type gui.component.TrainScheduleSelector
    local self = {}
    setmetatable(self, { __index = TrainScheduleSelector })

    self.id = component_id_sequence:next()

    self.name = "train_schedule_selector_" .. self.id

    self.context = assert(context, "context is empty")

    force = game.forces[context.force_name]
    assert(force, "force is empty")
    self.force = force

    surface = game.surfaces[context.surface_name]
    assert(surface, "surface is empty")
    self.surface = surface

    if selected_schedule ~= nil then
        self.selected_schedule = self:_prepare_schedule(selected_schedule)
    end

    if on_changed ~= nil then
        self.on_changed = on_changed
    end

    if required ~= nil then
        self.required = required
    end

    self:_initialize(container)

    self:_register_event_handlers()

    mod.log.debug("Component {1} created", { self.name }, self.name)

    return self
end

---@type string
function TrainScheduleSelector:read_form()
    local selected_schedule_index = self.refs.drop_down.selected_index

    return self.schedules[selected_schedule_index] ~= nil and self.schedules[selected_schedule_index].schedule or nil
end

function TrainScheduleSelector:validate_form()
    if self.required == false then
        return {}
    end

    return validator.validate(
            {
                {
                    match = validator.match_by_name({"value"}),
                    rules = { validator.rule_empty },
                }
            },
            { value = self:_get_value(self.refs) }
    )
end

function TrainScheduleSelector:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    self.refs.drop_down.destroy()
end

---@param container LuaGuiElement
function TrainScheduleSelector:_initialize(container)
    self.schedules = self:_get_schedules()

    local dropdown_values = flib_table.map(self.schedules, function(v) return v.name end)

    self.refs = flib_gui.build(container, { self:_structure(dropdown_values) })

    if #self.refs.drop_down.items > 0 then
        if self.selected_schedule == nil then
            self.refs.drop_down.selected_index = 1
        else
            ---@param s TrainSchedule
            for i, s in ipairs(self.schedules) do
                if self.selected_schedule.hash == s.hash then
                    self.refs.drop_down.selected_index = i
                end
            end
        end
    end

    -- todo use later
    --private.update_tooltip(self.refs, self.schedules)
end

function TrainScheduleSelector:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_train_schedule_selector_changed),
            handler = function(e) return self:__handle_on_changed(e) end
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

---@param refs table
---@return string
function TrainScheduleSelector:_get_value(refs)
    return refs.drop_down.items[refs.drop_down.selected_index]
end

---@param schedule TrainSchedule
---@return string
function TrainScheduleSelector:_make_schedule_name(schedule)
    local name = nil

    ---@param r TrainScheduleRecord
    for _, r in ipairs(schedule.records) do
        name = name == nil and r.station or name .. " - " .. r.station
    end

    return name
end

---@param schedule TrainSchedule
function TrainScheduleSelector:_prepare_schedule(schedule)
    ---@type TrainSchedule
    schedule = flib_table.deep_copy(schedule)
    schedule.current = 1

    return {
        hash = mod_table.hash_code(schedule.records),
        schedule = schedule,
        name = self:_make_schedule_name(schedule)
    }
end

---@return gui.component.TrainScheduleSelector.Schedule[]
function TrainScheduleSelector:_get_schedules()
    local schedules = {}

    --- Schedules from trains
    local trains = self.surface.get_trains(self.force)

    ---@param train LuaTrain`
    for _, train in ipairs(trains) do
        ---@type TrainSchedule
        local schedule = self:_prepare_schedule(train.schedule)

        table.insert(schedules, schedule.hash, schedule)
    end

    --- Schedules from templates
    local templates = persistence_storage.find_train_templates(self.context)

    ---@param template scripts.lib.domain.TrainTemplate
    for _, template in ipairs(templates) do
        ---@type TrainSchedule
        local schedule = self:_prepare_schedule(template.destination_schedule)

        table.insert(schedules, schedule.hash, schedule)
    end

    -- create new array with sequential keys
    return flib_table.filter(schedules, function() return true end, true)
end

---@param schedule TrainSchedule
---@return string
function TrainScheduleSelector:_make_tooltip_for_schedule(schedule)
    local tooltip

    ---@param record TrainScheduleRecord
    for _, record in ipairs(schedule.records) do
        tooltip = tooltip == nil and record.station or tooltip .. "\n" .. record.station;

        if record.wait_conditions ~= nil then
            local conditions = flib_table.reduce(
                    record.wait_conditions,
                    function(acc, v) return acc == "" and v.type or acc .. "," .. v.type end,
                    ""
            )

            tooltip = tooltip .. " (" .. conditions .. ")"
        end
    end

    return tooltip
end

---@param refs table
---@param schedules table
function TrainScheduleSelector._update_tooltip(refs, schedules)
    ---@type TrainSchedule
    local selected_schedule = schedules[refs.drop_down.selected_index]
    local tooltip = self:_make_tooltip_for_schedule(selected_schedule)

    flib_gui.update(refs.drop_down, {tooltip = tooltip})
end

---@param e scripts.lib.decorator.Event
function TrainScheduleSelector:__handle_on_changed(e)
    self.on_changed(e)
end

---@param values table list of values
function TrainScheduleSelector:_structure(values)
    return {
        type = "flow",
        direction = "vertical",
        children = {
            {
                type = "drop-down",
                ref = {"drop_down"},
                items = values,
                actions = { on_selection_state_changed = { event = mod.defines.events.on_gui_train_schedule_selector_changed },
                }
            },
        }
    }
end

return TrainScheduleSelector