local flib_direction = require('__flib__.direction')

local Context = require('scripts.lib.domain.Context')

local FORCE_DEFAULT = "player"

local rotate_relative_position = { --todo move to mod.direction module
    [defines.direction.north] = function(x, y)
        return x, y
    end,
    [defines.direction.east] = function(x, y)
        return y * -1, x
    end,
    [defines.direction.south] = function(x, y)
        return x * -1, y * -1
    end,
    [defines.direction.west] = function(x, y)
        return y, x * -1
    end,
}

local private = {}
local public = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.init()
    global.depot = {}
end

---@param context scripts.lib.domain.Context
---@param depot table
function storage.save_depot(context, depot)
    if global.depot[context.surface_name] == nil then
        global.depot[context.surface_name] = {}
    end

    global.depot[context.surface_name][context.force_name] = depot
end

---@param context scripts.lib.domain.Context
---@return table
function storage.get_depot(context)
    if global.depot[context.surface_name] == nil then
        return nil
    end

    return global.depot[context.surface_name][context.force_name]
end

---@param context scripts.lib.domain.Context
---@return table
function storage.delete_depot(context)
    if global.depot[context.surface_name] == nil then
        return
    end

    global.depot[context.surface_name][context.force_name] = nil
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param entity LuaEntity
function private.shadow_entity(entity)
    entity.force = FORCE_DEFAULT -- todo pass force as argument
    entity.operable = false
    entity.minable = false
    entity.destructible = false
    entity.rotatable = false
end

---@param rail_entity LuaEntity
---@param direction defines.direction
function private.build_rail_signal(rail_entity, direction)
    local force = rail_entity.force
    local x, y = rotate_relative_position[direction](1.5, 0)
    local rail_signal = rail_entity.surface.create_entity({
        name = mod.defines.prototypes.entity.depot_building_rail_signal.name,
        position = { rail_entity.position.x + x, rail_entity.position.y + y },
        direction = flib_direction.opposite(direction),
        force = force,
    })
    private.shadow_entity(rail_signal)
    rail_signal.operable = true -- todo ?

    return rail_signal
end

---@param surface LuaSurface
---@param force LuaForce
---@param start_position Position
---@param direction uint
---@param rails_count int
---@return table list of build rails
function private.build_straight_rails(surface, force, start_position, direction, rails_count)
    local rails = {}
    local rail
    local x, y

    for _ = 1, rails_count do
        rail = surface.create_entity({
            name = mod.defines.prototypes.entity.depot_building_straight_rail.name,
            position = start_position,
            direction = direction,
            force = force,
        })
        table.insert(rails, rail)

        x, y = rotate_relative_position[direction](0, 2)
        start_position = { x = rail.position.x + x, y = rail.position.y + y }
    end

    return rails
end

---@param entity LuaEntity
---@param direction defines.direction
---@return LuaEntity
function private.get_guideline(entity, direction)
    -- todo check entity type

    local function is_odd(number) return number % 2 == 1 end
    local entity_position = entity.position
    local x = entity_position.x
    local y = entity_position.y

    local variants = {
        {x = x, y = y - 1},
        {x = x, y = y + 1},
        {x = x - 1, y = y},
        {x = x + 1, y = y},
        {x = x - 1, y = y - 1},
        {x = x + 1, y = y - 1},
        {x = x + 1, y = y + 1},
        {x = x + 1, y = y + 1},
    }

    if is_odd(x) and is_odd(y) then
        return entity_position
    end

    for _, variant in ipairs(variants) do
        if is_odd(variant.x) and is_odd(variant.y) then
            return variant
        end
    end

    error('logical error')
end

---@param position Position
---@return bool
function private.is_wrong_place(position)
    local function is_odd(number) return number % 2 == 1 end

    return not is_odd(position.x) or not is_odd(position.y)
end

---@param player LuaPlayer
---@param position Position
function private.notify_about_wrong_place(player, position)
    player.surface.create_entity({
        name = "flying-text",
        text = "Wrong place: TODO", -- todo translate it
        position = position,
        color = {r = 1, g = 0.45, b = 0, a = 0.8},
        player = player,
    })
end

---@param entity LuaEntity
---@param context scripts.lib.domain.Context
function private.build(context, entity)
    local dependent_entities = {}
    ---@type LuaSurface
    local surface = entity.surface
    ---@type LuaForce
    local force = entity.force
    ---@type Position
    local guideline_coordinate = private.get_guideline(entity)
    local x, y
    local DEPOT_RAILS_COUNT = 8

    -- Input and output for logistic signals

    x, y = rotate_relative_position[entity.direction](0.5, 2.5)
    local depot_signals_input = surface.create_entity({
        name = mod.defines.prototypes.entity.depot_building_input.name,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = entity.direction,
        force = force,
    })
    private.shadow_entity(depot_signals_input)
    table.insert(dependent_entities, depot_signals_input)

    x, y = rotate_relative_position[entity.direction](-0.5, 2.5)
    local depot_signals_output = surface.create_entity({
        name = mod.defines.prototypes.entity.depot_building_output.name,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = entity.direction,
        force = force,
    })
    private.shadow_entity(depot_signals_output)
    table.insert(dependent_entities, depot_signals_output)

    -- Input station, rails and signals
    x, y = rotate_relative_position[entity.direction](6, 0)
    local depot_station_input = surface.create_entity({
        name = mod.defines.prototypes.entity.depot_building_train_stop_input.name,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = entity.direction,
        force = force,
    })
    private.shadow_entity(depot_station_input)
    table.insert(dependent_entities, depot_station_input)

    x, y = rotate_relative_position[entity.direction](4, -6)
    local input_rails = private.build_straight_rails(
            surface,
            force,
            {x = guideline_coordinate.x + x, y = guideline_coordinate.y + y},
            entity.direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(input_rails) do table.insert(dependent_entities, v) end
    local last_input_rail = input_rails[#input_rails]

    local input_rail_signal = private.build_rail_signal(last_input_rail, depot_station_input.direction)
    table.insert(dependent_entities, input_rail_signal)

    -- Output station, rails and signals
    x, y = rotate_relative_position[entity.direction](-6, 0)
    local depot_station_output = surface.create_entity({
        name = mod.defines.prototypes.entity.depot_building_train_stop_output.name,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = flib_direction.opposite(entity.direction),
        force = force,
    })
    private.shadow_entity(depot_station_output)
    table.insert(dependent_entities, depot_station_output)

    x, y = rotate_relative_position[entity.direction](-4, -6)

    local output_rails = private.build_straight_rails(
            surface,
            force,
            {x = guideline_coordinate.x + x, y = guideline_coordinate.y + y},
            entity.direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(output_rails) do table.insert(dependent_entities, v) end
    local last_output_rail = output_rails[#output_rails]

    local output_rail_signal = private.build_rail_signal(last_output_rail, depot_station_output.direction)
    table.insert(dependent_entities, output_rail_signal)

    storage.save_depot(context, {
        depot_entity = entity,
        output_station = depot_station_output,
        output_signal = output_rail_signal,
        dependent_entities = dependent_entities
    })

    mod.log.debug('Depot on surface {1} for force {2} was build', {context.surface_name, context.force_name})
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    storage.init()
end

---@param entity LuaEntity
---@return void
---@param player LuaPlayer
function public.build_ghost(player, entity)
    if private.is_wrong_place(entity.position) then
        private.notify_about_wrong_place(player, entity.position)

        entity.destroy()
        return
    end
end

---@param entity LuaEntity
---@return bool
function private.is_depot_part(entity)
    local context = Context.from_entity(entity)
    local depot = storage.get_depot(context)

    if depot.depot_entity == entity then
        return true
    end

    for _, dependent_entity in ipairs(depot.dependent_entities) do
        if dependent_entity == entity then
            return true
        end
    end

    return false
end

---@param entity LuaEntity
---@param player LuaPlayer
---@param old_direction defines.direction
function public.revert_rotation(player, entity, old_direction)
    local surface = entity.surface

    entity.direction = old_direction

    surface.create_entity({
        name = "flying-text",
        text = "Builded depot cant be rotated", -- todo translate it
        position = entity.position,
        color = mod.defines.color.red,
        player = player,
    })
end

---@param entity LuaEntity
---@param player LuaPlayer
function public.build(entity, player)
    if private.is_wrong_place(entity.position) then
        private.notify_about_wrong_place(player, entity.position)

        entity.destroy()

        if player then
            local inventory = player.get_main_inventory()
            inventory.insert({name=mod.defines.prototypes.item.depot_building.name, count=1})
        end

        return
    end

    local context = Context.from_entity(entity)

    private.build(context, entity)
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function public.get_depot_output_station(context)
    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    return depot.output_station
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function public.get_depot_output_signal(context)
    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    return depot.output_signal
end

---@param entity LuaEntity
---@return void
function public.destroy(entity)
    local context = Context.from_entity(entity)

    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    for _,e in ipairs(depot.dependent_entities) do
        e.destroy()
    end

    depot.depot_entity.destroy()

    storage.delete_depot(context)

    mod.log.debug('Depot on surface {1} for {2} was destroy', {context.surface_name, context.force_name})
end

return public