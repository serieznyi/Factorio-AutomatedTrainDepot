local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local mod_table = require("scripts.util.table")
local validator = require("scripts.gui.validator")
local Sequence = require("scripts.lib.Sequence")
local EventDispatcher = require("scripts.util.EventDispatcher")

local component_id_sequence = Sequence()

--- @module gui.component.TrainStationSelector
local TrainStationSelector = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    ---@type string
    selected_name = nil,
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
    on_changed = false,
}

---@param force LuaForce
---@param surface LuaSurface
---@param on_changed function
---@param selected_station_name string
---@return scripts.lib.domain.Train
---@param container LuaGuiElement
function TrainStationSelector.new(container, surface, force, on_changed, selected_station_name, required)
    ---@type gui.component.TrainStationSelector
    local self = {}
    setmetatable(self, { __index = TrainStationSelector })

    self.id = component_id_sequence:next()
    self.name = "train_station_selector_" .. self.id
    self.force = assert(force, "force is empty")
    self.surface = assert(surface, "surface is empty")
    self.required = required == nil and false or required
    self.on_changed = on_changed

    if selected_station_name ~= nil then
        self.selected_name = selected_station_name
    end

    if actions ~= nil then
        self.actions = actions
    end

    self:_initialize(container)

    mod.log.debug("Component {1} created", {self.name}, self.name)

    return self
end

---@type string
function TrainStationSelector:read_form()
    return self:_get_value()
end

---@param event scripts.lib.decorator.Event
function TrainStationSelector:__handle_on_changed(event)
    if self.on_changed then
        self.on_changed(event)
    end
end

function TrainStationSelector:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    self.refs.drop_down.destroy()

    mod.log.debug("Component {1} destroyed", {self.name}, self.name)
end

function TrainStationSelector:validate_form()
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
            { value = self:_get_value() }
    )
end

---@param container LuaGuiElement
function TrainStationSelector:_initialize(container)
    local train_stations = self:_get_train_stations()

    self.refs = flib_gui.build(container, { self:_structure(train_stations, self.actions) })

    if #self.refs.drop_down.items > 0 then
        if self.selected_name == nil then
            self.refs.drop_down.selected_index = 1
        else
            for i, s in ipairs(self.refs.drop_down.items) do
                if self.selected_name == s then
                    self.refs.drop_down.selected_index = i
                end
            end
        end
    end

    self:_register_event_handlers()
end

---@param values table
---@param actions table
function TrainStationSelector:_structure(values)
    return {
        type = "drop-down",
        ref = {"drop_down"},
        items = values,
        actions = {
            on_selection_state_changed = { event = mod.defines.events.on_gui_trains_station_selector_changed },
        },
    }
end

function TrainStationSelector:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_trains_station_selector_changed),
            handler = function(e) return self:__handle_on_changed(e) end
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

---@return string
function TrainStationSelector:_get_value()
    return self.refs.drop_down.items[self.refs.drop_down.selected_index]
end

---@param train_stations table
---@return table
function TrainStationSelector:_exclude_depot_train_stations(train_stations)
    local depot_train_stations_prototype_names = {
        mod.defines.prototypes.entity.depot_building_train_stop_input.name,
        mod.defines.prototypes.entity.depot_building_train_stop_output.name,
    }

    local function is_not_depot_train_station(station)
        return not flib_table.find(depot_train_stations_prototype_names, station.prototype.name)
    end

    return flib_table.filter(train_stations, is_not_depot_train_station, true)
end

function TrainStationSelector:_get_train_stations()
    local train_stations = game.get_train_stops({surface = self.surface, force = self.force})

    train_stations = self:_exclude_depot_train_stations(train_stations)

    ---@param station LuaEntity
    local train_stations_names = flib_table.map(train_stations, function(station)
        return station.backer_name
    end)

    train_stations_names = mod_table.array_unique(train_stations_names)

    table.sort(train_stations_names)

    return train_stations_names
end

return TrainStationSelector