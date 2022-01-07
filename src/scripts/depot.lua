local flib_direction = require('__flib__.direction')
local flib_gui = require("__flib__.gui")

local FORCE_DEFAULT = "player"
local DEPOT_RAILS_COUNT = 4
local RAIL_ENTITY_LENGTH = 2

local depot = {}

---@param entity LuaEntity
local function shadow_entity(entity)
    entity.force = FORCE_DEFAULT
    entity.operable = false
    entity.minable = false
    entity.destructible = false
    entity.rotatable = false
end

---@param rail_entity LuaEntity
---@param station_direction int
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

function depot.init()
    automated_train_depot.logger:debug("depot was init")

    global.depot = {
        guis = {},
    }
end

---@param entity LuaEntity
---@return void
function depot.build(entity)
    local dependent_entities = {}
    ---@type LuaSurface
    local surface = entity.surface

    -- Input and output for logistic signals

    local SIGNALS_POS_Y = entity.position.y + 5

    local depot_signals_input = surface.create_entity({
        name = automated_train_depot.constants.entity_names.depot_building_input,
        position = {entity.position.x + 2, SIGNALS_POS_Y}
    })
    shadow_entity(depot_signals_input)
    table.insert(dependent_entities, depot_signals_input)

    local depot_signals_output = surface.create_entity({
        name = automated_train_depot.constants.entity_names.depot_building_output,
        position = {entity.position.x - 1, SIGNALS_POS_Y}
    })
    shadow_entity(depot_signals_output)
    table.insert(dependent_entities, depot_signals_output)

    -- Input station, rails and signals

    local depot_station_input = surface.create_entity({
        name = automated_train_depot.constants.entity_names.depot_building_train_stop_input,
        position = {entity.position.x + 6.5, entity.position.y - 4.5}
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
        name = automated_train_depot.constants.entity_names.depot_building_train_stop_output,
        position = {entity.position.x - 5.5, entity.position.y - 4.5},
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

    automated_train_depot.depots[surface.name] = {
        depot_entity = entity,
        surface_name = surface.name,
        dependent_entities = dependent_entities
    }

    automated_train_depot.logger:debug('Entity ' .. entity.name .. '['.. entity.unit_number .. '] was build')
end

---@param depot_entity LuaEntity
---@return void
function depot.destroy(depot_entity)
    local surface = depot_entity.surface
    local depot_entity_id = depot_entity.unit_number
    local depot_for_destroy = automated_train_depot.depots[surface.name]
    local entity_name = depot_for_destroy.depot_entity.name;

    for _,e in pairs(depot_for_destroy.dependent_entities) do
        e.destroy()
    end

    depot_for_destroy.depot_entity.destroy()

    automated_train_depot.depots[surface.name] = nil

    automated_train_depot.logger:debug('Entity ' .. entity_name .. '['.. depot_entity_id .. '] was destroy')
end

---@param player LuaPlayer
---@param entity LuaEntity
function depot.create_gui(player, entity)
    local refs = flib_gui.build(player.gui.screen, {
        {
            type = "frame",
            name = "depot_main_frame",
            direction = "vertical",
            ref  =  {"window"},
            style_mods = {
                natural_width = 1200,
                natural_height = 400,
            },
            actions = {
                --on_closed = {gui = "demo", action = "close"} -- TODO
            },
            children = {
                -- Titlebar
                {
                    type = "flow",
                    style = "flib_titlebar_flow",
                    ref = {"titlebar_flow"},
                    children = {
                        {
                            type = "label",
                            style = "frame_title",
                            caption = {"gui-name.automated-train-depot-main-frame"},
                            ignored_by_interaction = true
                        },
                        {
                            type = "empty-widget",
                            style = "flib_titlebar_drag_handle",
                            ignored_by_interaction = true
                        },
                        {
                            type = "sprite-button",
                            style = "frame_action_button",
                            sprite = "utility/close_white",
                            hovered_sprite = "utility/close_black",
                            clicked_sprite = "utility/close_black",
                            ref = {"titlebar", "close_button"},
                            actions = {
                                on_click = {target = "depot", action = "close"}
                            }
                        }
                    }
                },
                -- Content
                {
                    type = "frame",
                    style = "inside_deep_frame_for_tabs",
                }
            }
        }
    })

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    player.opened = refs.window

    global.depot.guis[player.index] = {
        refs = refs,
        state = {
            entity = entity,
            previous_stats = "none",
        },
    }
end

function depot.destroy_gui(player)
    local gui_data = global.depot.guis[player.index]

    if gui_data then
        global.depot.guis[player.index] = nil
        gui_data.refs.window.destroy()
    end
end

---@param action table
---@param event EventData
function depot.handle_gui_action(action, event)
    if action.action == "close" then
        depot.gui_close(event)
    end
end

function depot.gui_close(event)
    local player = game.get_player(event.player_index)

    depot.destroy_gui(player)
end

return depot