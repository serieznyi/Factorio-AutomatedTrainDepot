local flib_direction = require('__flib__.direction')

local Context = require('lib.domain.Context')

local FORCE_DEFAULT = "player"
local DEPOT_RAILS_COUNT = 5
local RAIL_ENTITY_LENGTH = 2
local SIGNAL_TYPE = {
    NORMAL = "rail-signal",
    CHAIN = "rail-chain-signal",
}

local private = {}
local public = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param entity LuaEntity
function private.shadow_entity(entity)
    entity.force = FORCE_DEFAULT
    entity.operable = false
    entity.minable = false
    entity.destructible = false
    entity.rotatable = false
end

---@param rail_entity LuaEntity
---@param station_direction int
function private.build_rail_signal(rail_entity, signal_type, station_direction)
    local offset
    if station_direction == defines.direction.south then offset = -1.5 else offset = 1.5 end
    local rail_signal = rail_entity.surface.create_entity({
        name = signal_type,
        position = { rail_entity.position.x + offset, rail_entity.position.y },
        direction = flib_direction.opposite(station_direction)
    })
    private.shadow_entity(rail_signal)
    rail_signal.operable = true
    return rail_signal
end

---@param surface LuaSurface
---@param position Position
---@param direction uint
---@param rails_count int
---@return table list of build rails
function private.build_straight_rails(surface, position, direction, rails_count)
    local offset
    if direction == defines.direction.south then offset = -1.5 else offset = 1.5 end
    local railX = position.x - offset
    local rails = {}
    local rail
    for y = position.y, (position.y + (RAIL_ENTITY_LENGTH * rails_count)), RAIL_ENTITY_LENGTH do
        rail = nil
        rail = surface.create_entity({ name = "straight-rail",  position = { railX, y}})
        private.shadow_entity(rail)
        table.insert(rails, rail)
    end

    return rails
end

---@param station_entity LuaEntity
---@param railsCount int
---@return table list of build rails
function private.build_straight_rails_for_station(station_entity, railsCount)
    local offset
    if station_entity.direction == defines.direction.south then offset = -1.5 else offset = 1.5 end
    local railX = station_entity.position.x - offset
    local rails = {}
    local rail
    for y = station_entity.position.y, (station_entity.position.y + (RAIL_ENTITY_LENGTH * railsCount)), RAIL_ENTITY_LENGTH do
        rail = nil
        rail = station_entity.surface.create_entity({ name = "straight-rail",  position = { railX, y}})
        private.shadow_entity(rail)
        table.insert(rails, rail)
    end

    return rails
end

---@param context lib.domain.Context
---@param depot table
function private.save_depot(context, depot)
    if global.depot[context.surface_name] == nil then
        global.depot[context.surface_name] = {}
    end

    global.depot[context.surface_name][context.force_name] = depot
end

---@param context lib.domain.Context
---@return table
function private.get_depot(context)
    if global.depot[context.surface_name] == nil then
        return nil
    end

    return global.depot[context.surface_name][context.force_name]
end

---@param context lib.domain.Context
---@return table
function private.delete_depot(context)
    if global.depot[context.surface_name] == nil then
        return
    end

    global.depot[context.surface_name][context.force_name] = nil
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    global.depot = {}
end

---@param entity LuaEntity
---@return void
---@param player LuaPlayer
function public.build(player, entity)
    local dependent_entities = {}
    ---@type LuaSurface
    local surface = entity.surface

    -- Input and output for logistic signals

    local SIGNALS_POS_Y = entity.position.y + 5

    local depot_signals_input = surface.create_entity({
        name = mod.defines.entity.depot_building_input.name,
        position = {entity.position.x + 2, SIGNALS_POS_Y}
    })
    private.shadow_entity(depot_signals_input)
    table.insert(dependent_entities, depot_signals_input)

    local depot_signals_output = surface.create_entity({
        name = mod.defines.entity.depot_building_output.name,
        position = {entity.position.x - 1, SIGNALS_POS_Y}
    })
    private.shadow_entity(depot_signals_output)
    table.insert(dependent_entities, depot_signals_output)

    -- Input station, rails and signals

    local depot_station_input = surface.create_entity({
        name = mod.defines.entity.depot_building_train_stop_input.name,
        position = {entity.position.x + 6.5, entity.position.y - 4.5}
    })
    private.shadow_entity(depot_station_input)
    table.insert(dependent_entities, depot_station_input)

    local input_rails = private.build_straight_rails(
            surface,
            depot_station_input.position,
            depot_station_input.direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(input_rails) do table.insert(dependent_entities, v) end
    local last_input_rail = input_rails[#input_rails]

    local input_rail_signal = private.build_rail_signal(last_input_rail, SIGNAL_TYPE.NORMAL, depot_station_input.direction)
    table.insert(dependent_entities, input_rail_signal)

    -- Output station, rails and signals

    local depot_station_output = surface.create_entity({
        name = mod.defines.entity.depot_building_train_stop_output.name,
        position = {entity.position.x - 6, entity.position.y + 4},
        direction = defines.direction.south
    })
    depot_station_output.rotatable = true
    private.shadow_entity(depot_station_output)
    table.insert(dependent_entities, depot_station_output)

    local output_rails = private.build_straight_rails(
            surface,
            {x = entity.position.x - 5.5, y = entity.position.y - 4.5},
            depot_station_output.direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(output_rails) do table.insert(dependent_entities, v) end
    local last_output_rail = output_rails[#output_rails]

    local output_rail_signal = private.build_rail_signal(last_output_rail, SIGNAL_TYPE.CHAIN, depot_station_output.direction)
    table.insert(dependent_entities, output_rail_signal)

    local context = Context.from_player(player)
    private.save_depot(context, {
        depot_entity = entity,
        surface_name = surface.name,
        dependent_entities = dependent_entities
    })

    mod.log.debug('Depot on surface {1} for force {2} was build', {context.surface_name, context.force_name})
end

---@param player LuaPlayer
---@return void
function public.destroy(player)
    local context = Context.from_player(player)
    local depot = private.get_depot(context)

    if depot == nil then
        return
    end

    for _,e in ipairs(depot.dependent_entities) do
        e.destroy()
    end

    depot.depot_entity.destroy()

    private.delete_depot(context)

    mod.log.debug('Depot on surface {1} for {2} was destroy', {context.surface_name, context.force_name})
end

return public