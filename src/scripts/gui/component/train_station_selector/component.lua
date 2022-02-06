local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local validator = require("scripts.gui.validator")

local private = {}

---@param values table
---@param actions table
function private.build_structure(values, actions)
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

---@param force LuaForce
---@param surface LuaSurface
---@param selected_station_name string
function private.get_train_stations(surface, force, selected_station_name)
    local train_stations = game.get_train_stops({surface = surface, force = force})

    ---@param station LuaEntity
    local train_stations_names = flib_table.map(train_stations, function(station)
        return station.backer_name
    end)

    table.sort(train_stations_names)

    return flib_table.array_merge({
        selected_station_name == nil and {""} or {},
        train_stations_names,
    })
end

--- @module gui.component.TrainStationSelector
local TrainStationSelector = {
    ---@type string
    selected_station_name = nil,
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

    self.refs = flib_gui.build(container, { private.build_structure(train_stations, self.actions) })

    if self.selected_station_name == nil or self.selected_station_name == "" then
        self.refs.drop_down.selected_index = 1
    else
        for i, v in ipairs(self.refs.drop_down.items) do
            if v == self.selected_station_name then
                self.refs.drop_down.selected_index = i
            end
        end
    end
end

---@param force LuaForce
---@param surface LuaSurface
---@param actions table
---@param selected_station_name string
---@return lib.domain.Train
function TrainStationSelector.new(surface, force, actions, selected_station_name, required)
    ---@type gui.component.TrainStationSelector
    local self = {}
    setmetatable(self, { __index = TrainStationSelector })

    assert(force, "`force` is empty")
    self.force = force

    assert(surface, "`surface` is empty")
    self.surface = surface

    if selected_station_name ~= nil then
        self.selected_station_name = selected_station_name
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