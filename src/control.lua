local flib_event = require("__flib__.event")
local flib_dictionary = require("__flib__.dictionary")
local flib_on_tick_n = require("__flib__.on-tick-n")
local flib_gui = require("__flib__.gui")

local util_table = require("scripts.util.table")

mod = require("scripts.mod")

local event_handler = require("scripts.evens_control")
local depot_builder = require("scripts.lib.depot_builder")
local depot = require("scripts.lib.depot")
local gui_manager = require("scripts.gui.manager")
local console = require("scripts.console")
local persistence_storage = require("scripts.persistence.persistence_storage")
local train_service = require("scripts.lib.train_service")

---------------------------------------------------------------------------
-- -- -- INTERFACES
---------------------------------------------------------------------------

remote.add_interface('atd', {
    depot_get_output_station = depot_builder.get_depot_output_station,
    depot_get_output_signal = depot_builder.get_depot_output_signal,
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
    local player = game.get_player(command.player_index)

    if command.parameter == nil or global[command.parameter] == nil then
        return
    end

    local data = global[command.parameter]

    mod.log.debug(util_table.to_string(data))

    player.print("Global data from `" .. command.parameter .. "` writed in log file")
end)

--- Show keys from global table
---@param command CustomCommandData
commands.add_command("atd-global-keys", nil, function(command)
    local player = game.get_player(command.player_index)
    local data = {}

    for i, _ in pairs(global) do
        table.insert(data, {name = i, type = "persistence"})
    end

    for i, _ in pairs(mod.global) do
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

    -- Initialize `global` table
    console.init()
    persistence_storage.init()
    depot_builder.init()
    depot.init()
end)

-- Loaded save file what contains mod ; Cant write in global
flib_event.on_load(function()
    flib_dictionary.load()
    gui_manager.load()
    depot.load()
    persistence_storage.load()
end)

---------------------------------------------------------------------------
-- -- -- REGISTER ENTITY EVENTS
---------------------------------------------------------------------------

flib_event.register(
        {
            defines.events.on_train_created
        },
        event_handler.train_create
)

flib_event.register(
        {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            -- TODO check
            defines.events.script_raised_built,
            defines.events.script_raised_revive,
            defines.events.on_entity_cloned
        },
        event_handler.entity_build,
        {
            { filter="name", name= mod.defines.prototypes.entity.depot_building.name },
            { filter="ghost_name", name= mod.defines.prototypes.entity.depot_building.name },
        }
)

flib_event.register(
        defines.events.on_player_rotated_entity,
        event_handler.entity_rotated
)

flib_event.register(
        {
            defines.events.on_player_mined_entity,
            defines.events.on_robot_mined_entity,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
        },
        event_handler.entity_dismantled,
        {
            { filter="name", name= mod.defines.prototypes.entity.depot_building.name },
            { filter="rolling-stock" },
        }
)

flib_event.register(defines.events.on_runtime_mod_setting_changed, event_handler.reload_settings)

flib_event.register(util_table.array_values(mod.defines.events), event_handler.handle_events)

---------------------------------------------------------------------------
-- -- -- REGISTER GUI EVENTS
---------------------------------------------------------------------------

flib_gui.hook_events(event_handler.handle_events)

flib_event.register(defines.events.on_gui_opened, event_handler.open_main_frame)
flib_event.register(defines.events.on_gui_closed, event_handler.on_gui_closed)

---------------------------------------------------------------------------
-- -- -- NTH EVENTS
---------------------------------------------------------------------------

-- todo check performance
flib_event.on_nth_tick(mod.defines.on_nth_tick.persistence_storage_gc, persistence_storage.collect_garbage)

---------------------------------------------------------------------------
-- -- -- OTHER
---------------------------------------------------------------------------