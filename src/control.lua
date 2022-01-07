local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local on_tick_n = require("__flib__.on-tick-n")
local gui = require("__flib__.gui")

automated_train_depot = require("scripts.init_modification_state")

local event_handler = require("scripts.event_handler")
local depot = require("scripts.depot")

---------------------------------------------------------------------------
-- -- -- Main events
---------------------------------------------------------------------------

-- Game version changed
-- Any mod version changed
-- Any mod added
-- Any mod removed
-- Any mod prototypes changed
-- Any mod settings changed
script.on_configuration_changed(function(e)
    --if migration.on_config_changed(e, migrations.versions) then
    --    migrations.generic()
    --end
    -- TODO
end)

-- BOOTSTRAP

-- Save file created ;  Loaded save file what don`t contain mod ;  Can write in `global` and read `game`
event.on_init(function()
    -- Initialize libraries
    dictionary.init()
    on_tick_n.init()

    -- Initialize `global` table
    depot.init()
end)

-- Loaded save file what contains mod ; Cant write in global
event.on_load(function()
    dictionary.load()
    -- Restore local vars from `global`
    -- Re-register event handlers
    -- TODO
end)

---------------------------------------------------------------------------
-- -- -- ENTITY
---------------------------------------------------------------------------

event.register(
        {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            -- TODO check
            defines.events.script_raised_built,
            defines.events.script_raised_revive,
            defines.events.on_entity_cloned
        },
        event_handler.build_depot_entity,
        {{ filter="name", name= automated_train_depot.constants.entity_names.depot_building }}
)

event.register(
        {
            defines.events.on_pre_player_mined_item,
            defines.events.on_robot_pre_mined,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
        },
        event_handler.destroy_depot_entity,
        {{ filter="name", name= automated_train_depot.constants.entity_names.depot_building }}
)

event.register(defines.events.on_runtime_mod_setting_changed, event_handler.reload_settings)

---------------------------------------------------------------------------
-- -- -- GUI
---------------------------------------------------------------------------

gui.hook_events(event_handler.handle_gui_event)

event.register(defines.events.on_gui_opened, event_handler.open_gui)