local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local mod_table = require("scripts.util.table")
local validator = require("scripts.gui.validator")

local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param values table
---@param actions table
function private.structure(values, actions)
    return {
        type = "drop-down",
        ref = {"drop_down"},
        items = values,
        actions = actions,
    }
end

---@param refs table
---@return string
function private.get_value(refs)
    return refs.drop_down.items[refs.drop_down.selected_index]
end

---@param train_stations table
---@return table
function private.exclude_depot_train_stations(train_stations)
    local depot_train_stations_prototype_names = {
        mod.defines.prototypes.entity.depot_building_train_stop_input.name,
        mod.defines.prototypes.entity.depot_building_train_stop_output.name,
    }

    local function is_not_depot_train_station(station)
        return not flib_table.find(depot_train_stations_prototype_names, station.prototype.name)
    end

    return flib_table.filter(train_stations, is_not_depot_train_station, true)
end

---@param force LuaForce
---@param surface LuaSurface
function private.get_train_stations(surface, force)
    local train_stations = game.get_train_stops({surface = surface, force = force})

    train_stations = private.exclude_depot_train_stations(train_stations)

    ---@param station LuaEntity
    local train_stations_names = flib_table.map(train_stations, function(station)
        return station.backer_name
    end)

    train_stations_names = mod_table.array_unique(train_stations_names)

    table.sort(train_stations_names)

    return train_stations_names
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

--- @module gui.component.TrainStationSelector
local TrainStationSelector = {
    ---@type string
    selected_name = nil,
    ---@type LuaForce
    force = nil,
    ---@type LuaSurface
    surface = nil,
    ---@type table
    actions = {},
    ---@type table
    refs = nil,
    ---@type bool
    required = false,
}

---@type string
function TrainStationSelector:read_form()
    return private.get_value(self.refs)
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
            { value = private.get_value(self.refs) }
    )
end

---@param container LuaGuiElement
function TrainStationSelector:build(container)
    local train_stations = private.get_train_stations(self.surface, self.force)

    self.refs = flib_gui.build(container, { private.structure(train_stations, self.actions) })

    if self.selected_name == nil then
        self.refs.drop_down.selected_index = 1
    else
        for i, v in ipairs(self.refs.drop_down.items) do
            if v == self.selected_name then
                self.refs.drop_down.selected_index = i
            end
        end
    end
end

---@param force LuaForce
---@param surface LuaSurface
---@param actions table
---@param selected_station_name string
---@return scripts.lib.domain.Train
function TrainStationSelector.new(surface, force, actions, selected_station_name, required)
    ---@type gui.component.TrainStationSelector
    local self = {}
    setmetatable(self, { __index = TrainStationSelector })

    assert(force, "`force` is empty")
    self.force = force

    assert(surface, "`surface` is empty")
    self.surface = surface

    if selected_station_name ~= nil then
        self.selected_name = selected_station_name
    end

    if actions ~= nil then
        self.actions = actions
    end

    if required ~= nil then
        self.required = required
    end

    mod.log.debug("Component created", {}, "gui.component.train_station_selector")

    return self
end

return TrainStationSelector