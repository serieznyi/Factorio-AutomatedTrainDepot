local flib_direction = require('__flib__.direction')

local logger = require("scripts.lib.logger")
local Context = require('scripts.lib.domain.Context')
local persistence_storage = require("scripts.persistence.persistence_storage")
local util_table = require("scripts.util.table")

local FORCE_DEFAULT = "player"

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

    persistence_storage.depot_build_at(context)
end

---@param context scripts.lib.domain.Context
---@param depot_building LuaEntity
function storage.add_depot_building(context, depot_building)
    assert(global.depot[context.surface_name], 'depot not exists')

    global.depot[context.surface_name][context.force_name].depot_entity = depot_building
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

    persistence_storage.depot_destroyed_at(context)
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param entity LuaEntity
---@param text table|string
---@param color table
function private.entity_flying_text(entity, text, color)
    entity.surface.create_entity({
        type = "flying-text",
        name = "flying-text",
        position = entity.position,
        text = text,
        color = color,
    })
end

---@param entity LuaEntity
---@param text table
function private.flying_message(entity, text)
    private.entity_flying_text(entity, text, atd.defines.color.white)
end

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
function private.build_rail_signal(signal_entity, rail_entity, direction)
    local force = rail_entity.force
    local x, y = atd.defines.rotate_relative_position[direction](1.5, 0)
    local rail_signal = rail_entity.surface.create_entity({
        name = signal_entity,
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
---@param start_position MapPosition
---@param direction uint
---@param rails_count int
---@return table list of build rails
function private.build_straight_rails(surface, force, start_position, direction, rails_count)
    local rails = {}
    local rail
    local x, y

    for _ = 1, rails_count do
        rail = surface.create_entity({
            name = atd.defines.prototypes.entity.depot_building.parts.straight_rail,
            position = start_position,
            direction = direction,
            force = force,
        })
        table.insert(rails, rail)

        x, y = atd.defines.rotate_relative_position[direction](0, 2)
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

---@param position MapPosition
---@return bool
function private.is_wrong_place(position)
    local function is_odd(number) return number % 2 == 1 end

    return not is_odd(position.x) or not is_odd(position.y)
end

---@param entity LuaEntity
---@param context scripts.lib.domain.Context
function private.replace_entity_on_depot(context, entity)
    local depot_position = entity.position
    local depot_direction = entity.direction

    entity.destroy{raise_destroy=false}

    return context:surface().create_entity({
        name = atd.defines.prototypes.entity.depot_building.name,
        position = depot_position,
        direction = depot_direction,
        force = context:force(),
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
    ---@type MapPosition
    local guideline_coordinate = private.get_guideline(entity)
    local x, y
    local DEPOT_RAILS_COUNT = 7
    local original_entity_direction = entity.direction
    local real_depot_entity = private.replace_entity_on_depot(context, entity)

    -- Storage - Requester

    x, y = atd.defines.rotate_relative_position[original_entity_direction](5.5, 2.5)
    local depot_storage_requester = surface.create_entity({
        name = atd.defines.prototypes.entity.depot_building.parts.storage_requester,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        force = force,
    })
    depot_storage_requester.minable = false
    depot_storage_requester.destructible = false

    table.insert(dependent_entities, depot_storage_requester)

    -- Storage - Provider

    x, y = atd.defines.rotate_relative_position[original_entity_direction](5.5, -2.5)
    local depot_storage_provider = surface.create_entity({
        name = atd.defines.prototypes.entity.depot_building.parts.storage_provider,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        force = force,
    })
    depot_storage_provider.minable = false
    depot_storage_provider.destructible = false

    table.insert(dependent_entities, depot_storage_provider)

    -- Input station, rails and signal
    x, y = atd.defines.rotate_relative_position[original_entity_direction](6, -6)
    local depot_station_input = surface.create_entity({
        name = atd.defines.prototypes.entity.depot_building.parts.train_stop,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = original_entity_direction,
        force = force,
    })
    depot_station_input.backer_name = "Depot input station",
    private.shadow_entity(depot_station_input)
    table.insert(dependent_entities, depot_station_input)

    x, y = atd.defines.rotate_relative_position[original_entity_direction](4, -6)
    local input_rails = private.build_straight_rails(
            surface,
            force,
            {x = guideline_coordinate.x + x, y = guideline_coordinate.y + y},
            original_entity_direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(input_rails) do table.insert(dependent_entities, v) end
    local last_input_rail = input_rails[#input_rails]

    local input_rail_signal = private.build_rail_signal(
            atd.defines.prototypes.entity.depot_building.parts.rail_signal,
            last_input_rail,
            depot_station_input.direction
    )
    table.insert(dependent_entities, input_rail_signal)

    -- Output station, rails and signal
    x, y = atd.defines.rotate_relative_position[original_entity_direction](-6, 0)
    local depot_station_output = surface.create_entity({
        name = atd.defines.prototypes.entity.depot_building.parts.train_stop,
        position = {guideline_coordinate.x + x, guideline_coordinate.y + y},
        direction = flib_direction.opposite(original_entity_direction),
        force = force,
    })
    depot_station_output.backer_name = "Depot output station",
    private.shadow_entity(depot_station_output)
    table.insert(dependent_entities, depot_station_output)

    x, y = atd.defines.rotate_relative_position[original_entity_direction](-4, -6)

    local output_rails = private.build_straight_rails(
            surface,
            force,
            {x = guideline_coordinate.x + x, y = guideline_coordinate.y + y},
            original_entity_direction,
            DEPOT_RAILS_COUNT
    )
    for _,v in ipairs(output_rails) do table.insert(dependent_entities, v) end
    local last_output_rail = output_rails[#output_rails]

    local output_rail_signal = private.build_rail_signal(
            atd.defines.prototypes.entity.depot_building.parts.rail_chain_signal,
            last_output_rail,
            depot_station_output.direction
    )
    table.insert(dependent_entities, output_rail_signal)

    storage.save_depot(context, {
        depot_entity = real_depot_entity,
        output_station = depot_station_output,
        input_station = depot_station_input,
        output_signal = output_rail_signal,
        depot_storage = depot_storage_requester,
        depot_storage_provider = depot_storage_provider,
        dependent_entities = dependent_entities,
    })

    logger.debug('Depot on surface {1} for force {2} was build', {context.surface_name, context.force_name})
end

---@param player LuaPlayer
function private.return_depot_in_inventory(player)
    local inventory = player.get_main_inventory()
    inventory.insert({ name= atd.defines.prototypes.item.depot_building, count=1})
end

---@param entity LuaEntity
---@return bool true if building break
function private.try_break_building(entity)
    local context = Context.from_entity(entity)
    local depot_exists = storage.get_depot(context)
    local wrong_place = private.is_wrong_place(entity.position)
    local broken = false

    if wrong_place or depot_exists then
        broken = true

        if depot_exists then
            private.flying_message(entity, { "flying-text.atd-only-one-depot-per-surface"})
        else
            private.flying_message(entity, { "flying-text.atd-depot-wrong-place"})
        end

        entity.destroy()
    end

    return broken
end

---@param entity LuaEntity
---@return bool true
function private.has_depot_active_tasks(entity)
    local context = Context.from_entity(entity)

    return persistence_storage.trains_tasks.count_tasks(context) == 0
end

---@param depot_building_entity LuaEntity
---@param player_index uint|nil
---@param robot LuaEntity|nil
---@return bool true
function private.has_place_in_inventory(depot_building_entity, player_index, robot)
    -- todo

    return true
end

---@param entity LuaEntity
function private.restore_main_entity(entity)
    local depot_building = entity.surface.create_entity({
        name = entity.name,
        position = entity.position,
        direction = entity.direction,
        force = entity.force,
        raise_built = false,
    })

    local context = Context.from_entity(depot_building)

    storage.add_depot_building(context, depot_building)

    private.flying_message(entity, { "flying-text.atd-cant-remove-depot-with-active-tasks"})

    logger.debug("Restore depot building after removing", {}, "depot_building")
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
function public.build_ghost(entity)
    private.try_break_building(entity)
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
function public.build(entity, player)
    if private.try_break_building(entity) then
        if player then
            private.return_depot_in_inventory(player)
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
function public.get_depot_input_station(context)
    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    return depot.input_station
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

---@param storage_type string
---@param context scripts.lib.domain.Context
---@return LuaEntity
function public.get_depot_storage(storage_type, context)
    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    if storage_type == atd.defines.storage_type.provider then
        return depot.depot_storage_provider
    end

    return depot.depot_storage
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function public.get_depot(context)
    local depot = storage.get_depot(context)

    if depot == nil then
        return
    end

    return depot.depot_entity
end

---@param context scripts.lib.domain.Context
---@return LuaEntity
function public.depot_building_exists(context)
    local depot = storage.get_depot(context)

    return depot ~= nil
end

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

    script.raise_event(atd.defines.events.on_core_depot_building_removed, {
        surface_name = context.surface_name, force_name = context.force_name
    })

    logger.debug('Depot on surface {1} for {2} was destroy', {context.surface_name, context.force_name})
end

---@param entity LuaEntity
---@param buffer_inventory LuaInventory
---@param player_index uint|nil
---@param robot LuaEntity|nil
function public.try_mine(entity, buffer_inventory, player_index, robot)
    if not private.has_depot_active_tasks(entity) or not private.has_place_in_inventory(entity, player_index, robot) then
        buffer_inventory.clear()
        private.restore_main_entity(entity)

        return
    end

    -- todo grab storage items

    public.destroy(entity)
end

return public