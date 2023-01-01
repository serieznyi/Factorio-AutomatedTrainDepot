local flib_event = require("__flib__.event")
local flib_dictionary = require("__flib__.dictionary")
local flib_on_tick_n = require("__flib__.on-tick-n")
local flib_gui = require("__flib__.gui")

local util_table = require("scripts.util.table")
local logger = require("scripts.lib.logger")

atd = require("scripts.mod")

local events_control = require("scripts.evens_control")
local depot_builder = require("scripts.lib.depot_builder")
local tasks_processor = require("scripts.lib.tasks_processor")
local gui_manager = require("scripts.gui.manager")
local console = require("scripts.console")
local persistence_storage = require("scripts.persistence.persistence_storage")
local train_service = require("scripts.lib.train.train_service")

---------------------------------------------------------------------------
-- -- -- INTERFACES
---------------------------------------------------------------------------

remote.add_interface('atd', {
    depot_get_output_station = depot_builder.get_depot_output_station,
    depot_get_input_station = depot_builder.get_depot_input_station,
    depot_get_output_signal = depot_builder.get_depot_output_signal,
    depot_get_storage = depot_builder.get_depot_storage,
    depot_get_depot = depot_builder.get_depot,
    depot_building_exists = depot_builder.depot_building_exists,
})

---------------------------------------------------------------------------
-- -- -- CONSOLE COMMANDS
---------------------------------------------------------------------------

--- Try register unregistered trains
commands.add_command("atd-register-trains", {"command.atd-register-trains-help"}, function(_)
    train_service.register_trains()
end)

--- Log variable from global table in log file
---@param command CustomCommandData
commands.add_command("atd-global-log", nil, function(command)
    ---@type LuaPlayer
    local player = game.get_player(command.player_index)
    local key = command.parameter

    if key == nil or (global[key] == nil and atd.global[key] == nil) then
        player.print("Data by key `" .. key .. "` not found", {1.0, 1.0, 0})
        return
    end

    local data = global[key] ~= nil and global[key] or atd.global[key]

    logger.debug(util_table.to_string(data), {}, key)

    player.print("Global data from `" .. key .. "` writed in log file")
end)

--- Show keys from global table
---@param command CustomCommandData
commands.add_command("atd-global-keys", nil, function(command)
    local player = game.get_player(command.player_index)
    local data = {}

    for i, _ in pairs(global) do
        table.insert(data, {name = i, type = "persistence"})
    end

    for i, _ in pairs(atd.global) do
        table.insert(data, {name = i, type = "in-memory"})
    end

    for _, value in ipairs(data) do
        player.print("[" .. value.type .. "] " .. value.name)
    end
end)

---------------------------------------------------------------------------
-- -- -- REGISTER MAIN EVENTS
---------------------------------------------------------------------------

-- Game version changed
-- Any mod version changed
-- Any mod added
-- Any mod removed
-- Any mod prototypes changed
-- Any mod settings changed
script.on_configuration_changed(function(e)
    flib_dictionary.init()

    --if migration.on_config_changed(e, migrations.versions) then
    --    migrations.generic()
    --end
end)

-- BOOTSTRAP

flib_event.on_init(function()
    -- Initialize libraries
    flib_dictionary.init()
    flib_on_tick_n.init()

    -- Initialize mod
    events_control.initialize()
    console.init()
    persistence_storage.init()
    depot_builder.init()
    tasks_processor.init()
    train_service.init()
end)

-- Loaded save file what contains mod ; Cant write in global
flib_event.on_load(function()
    -- Initialize libraries
    flib_dictionary.load()

    -- Initialize mod
    events_control.initialize()
    gui_manager.load()
    tasks_processor.load()
    train_service.load()
    persistence_storage.load()
end)

---------------------------------------------------------------------------
-- -- -- REGISTER ENTITY EVENTS
---------------------------------------------------------------------------

flib_event.register({
    defines.events.on_train_changed_state,
    defines.events.on_train_created,
}, events_control.handle_events)

flib_event.register(
        {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            -- TODO check
            defines.events.script_raised_built,
            defines.events.script_raised_revive,
            defines.events.on_entity_cloned
        },
        events_control.entity_build,
        {
            { filter="name", name= atd.defines.prototypes.entity.depot_building.name },
            { filter="ghost_name", name= atd.defines.prototypes.entity.depot_building.name },
        }
)

flib_event.register(
        defines.events.on_player_rotated_entity,
        events_control.entity_rotated
)

flib_event.register(
        {
            defines.events.on_player_mined_entity,
            defines.events.on_robot_mined_entity,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
        },
        events_control.entity_dismantled,
        {
            { filter="name", name=atd.defines.prototypes.entity.depot_building.name },
            { filter="rolling-stock" },
        }
)

flib_event.register(defines.events.on_runtime_mod_setting_changed, events_control.reload_settings)

flib_event.register(util_table.array_values(atd.defines.events), events_control.handle_events)

---------------------------------------------------------------------------
-- -- -- REGISTER GUI EVENTS
---------------------------------------------------------------------------

flib_gui.hook_events(events_control.handle_events)

flib_event.register(defines.events.on_gui_opened, events_control.open_main_frame)
flib_event.register(defines.events.on_gui_closed, events_control.on_gui_closed)

---------------------------------------------------------------------------
-- -- -- NTH EVENTS
---------------------------------------------------------------------------

-- todo check performance
flib_event.on_nth_tick(atd.defines.on_nth_tick.persistence_storage_gc, persistence_storage.collect_garbage)

---------------------------------------------------------------------------
-- -- -- OTHER
---------------------------------------------------------------------------