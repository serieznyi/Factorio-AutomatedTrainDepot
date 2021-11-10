local depot = {}

---@param entity LuaEntity
local function shadow_entity(entity)
    entity.force = entity.force
    entity.operable = false
    entity.minable = false
    entity.destructible = false
end

---@param entity LuaEntity
---@return void
function depot:build(entity)
    modificationState.logger:debug(entity.name .. " was builded")

    ---@type LuaEntity building_input
    local depot_input = entity.surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_input,
        position = {entity.position.x + 2, entity.position.y + 2}
    })
    shadow_entity(depot_input)

    ---@type LuaEntity building_output
    local depot_output = entity.surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_output,
        position = {entity.position.x - 1, entity.position.y + 2}
    })
    shadow_entity(depot_input)

    ---@type LuaEntity building_train_stop_input
    local depot_station_input = entity.surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_train_stop_input,
        position = {entity.position.x + 6.5, entity.position.y - 3.5}
    })
    shadow_entity(depot_input)
    --depot_station_input.direction = defines.direction.north
    --depot_station_input.orientation = 0.0 -- North

    -----@type LuaEntity building_train_stop_output
    local depot_station_output = entity.surface.create_entity({
        name = modificationState.constants.entity_names.depot_building_train_stop_output,
        position = {entity.position.x - 5.5, entity.position.y - 3.5}
    })
    shadow_entity(depot_input)
    depot_station_output.rotate({ reverse = true})
    --depot_station_output.direction = defines.direction.south
    --depot_station_output.orientation = 0.5 -- South

    modificationState.registered_depots[entity.unit_number] = {
        depot_entity = entity,
        dependent_entities = {
            depot_input = depot_input,
            depot_output = depot_output,
            depot_station_input = depot_station_input,
            depot_station_output = depot_station_output,
        }
    }
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