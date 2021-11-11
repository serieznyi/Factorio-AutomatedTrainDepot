local depot = {}

local DEPOT_RAILS_COUNT = 7
local RAIL_ENTITY_LENGTH = 2

---@param entity LuaEntity
local function shadow_entity(entity)
    entity.force = entity.force
    entity.operable = false
    entity.minable = false
    entity.destructible = false
    entity.rotatable = false
end

---@param entity LuaEntity
---@param length int
---@return table list of build rails
local function build_straight_rails_from_station(station_entity, railsCount)
    local rail
    local railX = station_entity.position.x - 1.5
    local build_rails = {}
    for y = station_entity.position.y, (station_entity.position.y + (RAIL_ENTITY_LENGTH * railsCount)), RAIL_ENTITY_LENGTH do
        rail = nil
        rail = surface.create_entity({
            name = "straight-rail",
            position = { railX, y},
        })
        shadow_entity(rail)
        table.insert(build_rails, lastRail)
    end

    return build_rails
end

---@param entity LuaEntity
---@return void
function depot:build(entity)
    local dependent_entities = {}
    local surface = entity.surface

    -- Input and output for logistic signals

    local depot_input = surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_input,
        position = {entity.position.x + 2, entity.position.y + 2}
    })
    shadow_entity(depot_input)
    table.insert(dependent_entities, depot_input)

    local depot_output = surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_output,
        position = {entity.position.x - 1, entity.position.y + 2}
    })
    shadow_entity(depot_output)
    table.insert(dependent_entities, depot_output)

    -- Input station, rails and signals

    local depot_station_input = surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_train_stop_input,
        position = {entity.position.x + 6.5, entity.position.y - 3.5}
    })
    shadow_entity(depot_station_input)
    table.insert(dependent_entities, depot_station_input)

    local railInput
    local railInputPositionX = depot_station_input.position.x - 1.5
    for y = depot_station_input.position.y, (depot_station_input.position.y + (RAIL_ENTITY_LENGTH * DEPOT_RAILS_COUNT)), RAIL_ENTITY_LENGTH do
        railInput = nil
        railInput = surface.create_entity({
            name = "straight-rail",
            position = { railInputPositionX, y},
        })
        game.print("rail - " .. railInputPositionX .. " - " .. y)
        shadow_entity(railInput)
        table.insert(dependent_entities, railInput)
    end

    local inputRailSignal = surface.create_entity({
        name = "rail-signal",
        position = { railInput.position.x + 1.5, railInput.position.y },
    })
    shadow_entity(inputRailSignal)
    table.insert(dependent_entities, inputRailSignal)

    ---- Output station, rails and signals

    local depot_station_output = surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_train_stop_output,
        position = {entity.position.x - 5.5, entity.position.y - 3.5},
        direction = defines.direction.south
    })
    depot_station_output.rotatable = true
    shadow_entity(depot_station_output)
    table.insert(dependent_entities, depot_station_output)

    local railOutput
    local railOutputPositionX = depot_station_output.position.x + 1.5
    for y = depot_station_output.position.y, (depot_station_output.position.y + (RAIL_ENTITY_LENGTH * DEPOT_RAILS_COUNT)), RAIL_ENTITY_LENGTH do
        railOutput = nil
        railOutput = surface.create_entity({
            name = "straight-rail",
            position = { railOutputPositionX, y},
        })
        shadow_entity(railOutput)
        table.insert(dependent_entities, railOutput)
    end

    local outputRailSignal = surface.create_entity({
        name = "rail-signal",
        position = { railOutput.position.x - 1.5, railOutput.position.y },
        direction = defines.direction.south
    })
    shadow_entity(outputRailSignal)
    table.insert(dependent_entities, outputRailSignal)

    modificationState.registered_depots[entity.unit_number] = {
        depot_entity = entity,
        dependent_entities = dependent_entities
    }

    modificationState.logger:debug(entity.name .. " was builded")
end

---@param entity LuaEntity
---@return void
function depot:destroy(entity)
    local registered_depot = modificationState.registered_depots[entity.unit_number]

    modificationState.registered_depots[entity.unit_number] = nil

    for _,e in pairs(registered_depot.dependent_entities) do
        e.destroy()
    end
end

return depot