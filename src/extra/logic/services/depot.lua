local flib_direction = require('__flib__.direction')

local depot = {}

local FORCE_DEFAULT = "player"
local DEPOT_RAILS_COUNT = 6
local RAIL_ENTITY_LENGTH = 2

---@param entity LuaEntity
local function shadow_entity(entity)
    entity.force = FORCE_DEFAULT
    entity.operable = false
    entity.minable = false
    entity.destructible = false
    entity.rotatable = false
end

---@param rail_entity LuaEntity
---@param direction int
local function build_rail_signal(rail_entity, station_direction)
    local offset
    if station_direction == defines.direction.south then offset = -1.5 else offset = 1.5 end
    local rail_signal = rail_entity.surface.create_entity({
        name = "rail-signal",
        position = { rail_entity.position.x + offset, rail_entity.position.y },
        direction = flib_direction.opposite(station_direction)
    })
    shadow_entity(rail_signal)
    rail_signal.operable = true
    return rail_signal
end

---@param station_entity LuaEntity
---@param railsCount int
---@return table list of build rails
local function build_straight_rails_for_station(station_entity, railsCount)
    local offset
    if station_entity.direction == defines.direction.south then offset = -1.5 else offset = 1.5 end
    local railX = station_entity.position.x - offset
    local rails = {}
    local rail
    for y = station_entity.position.y, (station_entity.position.y + (RAIL_ENTITY_LENGTH * railsCount)), RAIL_ENTITY_LENGTH do
        rail = nil
        rail = station_entity.surface.create_entity({ name = "straight-rail",  position = { railX, y}})
        shadow_entity(rail)
        table.insert(rails, rail)
    end

    return rails
end

---@param entity LuaEntity
---@return void
function depot:build(entity)
    local dependent_entities = {}
    local surface = entity.surface

    -- Input and output for logistic signals

    local depot_signals_input = surface.create_entity({
        name = modification_state.constants.entity_names.depot_building_input,
        position = {entity.position.x + 2, entity.position.y + 2}
    })
    shadow_entity(depot_signals_input)
    table.insert(dependent_entities, depot_signals_input)

    local depot_signals_output = surface.create_entity({
        name = modification_state.constants.entity_names.depot_building_output,
        position = {entity.position.x - 1, entity.position.y + 2}
    })
    shadow_entity(depot_signals_output)
    table.insert(dependent_entities, depot_signals_output)

    -- Input station, rails and signals

    local depot_station_input = surface.create_entity({
        name = modification_state.constants.entity_names.depot_building_train_stop_input,
        position = {entity.position.x + 6.5, entity.position.y - 3.5}
    })
    shadow_entity(depot_station_input)
    table.insert(dependent_entities, depot_station_input)

    local input_rails = build_straight_rails_for_station(depot_station_input, DEPOT_RAILS_COUNT)
    for _,v in ipairs(input_rails) do table.insert(dependent_entities, v) end
    local last_input_rail = input_rails[#input_rails]

    local input_rail_signal = build_rail_signal(last_input_rail, depot_station_input.direction)
    table.insert(dependent_entities, input_rail_signal)

    ---- Output station, rails and signals

    local depot_station_output = surface.create_entity({
        name = modification_state.constants.entity_names.depot_building_train_stop_output,
        position = {entity.position.x - 5.5, entity.position.y - 3.5},
        direction = defines.direction.south
    })
    depot_station_output.rotatable = true
    shadow_entity(depot_station_output)
    table.insert(dependent_entities, depot_station_output)

    local output_rails = build_straight_rails_for_station(depot_station_output, DEPOT_RAILS_COUNT)
    for _,v in ipairs(output_rails) do table.insert(dependent_entities, v) end
    local lastOutputRail = output_rails[#output_rails]

    local output_rail_signal = build_rail_signal(lastOutputRail, depot_station_output.direction)
    table.insert(dependent_entities, output_rail_signal)

    modification_state.registered_depots[entity.unit_number] = {
        depot_entity = entity,
        dependent_entities = dependent_entities
    }

    modification_state.logger:debug(entity.name .. " was builded")
end

---@param entity LuaEntity
---@return void
function depot:destroy(entity)
    local registered_depot = modification_state.registered_depots[entity.unit_number]

    modification_state.registered_depots[entity.unit_number] = nil

    for _,e in pairs(registered_depot.dependent_entities) do
        e.destroy()
    end
end

return depot