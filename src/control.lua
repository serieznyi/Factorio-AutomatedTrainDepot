local flib_event = require("__flib__.event")
local flib_dictionary = require("__flib__.dictionary")
local flib_on_tick_n = require("__flib__.on-tick-n")
local flib_gui = require("__flib__.gui")

mod = require("scripts.mod")

local event_handler = require("scripts.event_handler")
local depot_building = require("scripts.depot.depot_building")
local depot = require("scripts.depot.depot")
local gui_index = require("scripts.gui.manager")
local console = require("scripts.console")
local persistence_storage = require("scripts.persistence_storage")

---------------------------------------------------------------------------
-- -- -- INTERFACES
---------------------------------------------------------------------------

remote.add_interface('atd', {
    depot_get_output_station = depot.get_depot_output_station
})

---------------------------------------------------------------------------
-- -- -- CONSOLE COMMANDS
---------------------------------------------------------------------------

commands.add_command("atd-register-trains", {"command.atd-register-trains-help"}, function(_)
    depot.register_trains()
end)

---@param command CustomCommandData
commands.add_command("atd-global-print", nil, function(command)
    local player = game.get_player(command.player_index)
    local data = global[command.parameter]

    player.print(mod.util.table.to_string(data))
end)

---@param command CustomCommandData
commands.add_command("atd-global-keys", nil, function(command)
    local player = game.get_player(command.player_index)
    local keys = {}

    for i, _ in pairs(global) do
        table.insert(keys, i)
    end

    player.print(mod.util.table.to_string(keys))
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

    -- Initialize `global` table for gui
    gui_index.init()

    -- Initialize `global` table
    console.init()
    persistence_storage.init()
    depot_building.init()
    depot.init()
end)

-- Loaded save file what contains mod ; Cant write in global
flib_event.on_load(function()
    gui_index.load()
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
            { filter="name", name= mod.defines.entity.depot_building.name },
        }
)

flib_event.register(
        {
            defines.events.on_pre_player_mined_item,
            defines.events.on_robot_pre_mined,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
        },
        event_handler.entity_dismantled,
        {
            { filter="name", name= mod.defines.entity.depot_building.name },
            { filter="rolling-stock" },
        }
)

flib_event.register(defines.events.on_runtime_mod_setting_changed, event_handler.reload_settings)

-- todo remove it
flib_event.register(mod.util.table.array_values(mod.defines.events), event_handler.pass_to_gui)

---------------------------------------------------------------------------
-- -- -- REGISTER GUI EVENTS
---------------------------------------------------------------------------

flib_gui.hook_events(event_handler.handle_gui_event)

flib_event.register(defines.events.on_gui_opened, event_handler.open_gui)

---------------------------------------------------------------------------
-- -- -- NTH EVENTS
---------------------------------------------------------------------------

-- todo try bring to from inside frame
-- todo регистрировать только если окно открыто
flib_event.on_nth_tick(1, event_handler.bring_to_front_current_window)

-- todo check performance
flib_event.on_nth_tick(mod.defines.on_nth_tick.persistence_storage_gc, persistence_storage.collect_garbage)

---------------------------------------------------------------------------
-- -- -- OTHER
---------------------------------------------------------------------------