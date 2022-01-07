local event = require("__flib__.event")
local dictionary = require("__flib__.dictionary")
local on_tick_n = require("__flib__.on-tick-n")
local gui = require("__flib__.gui")

automated_train_depot = require("scripts.init_modification_state")

local event_handler = require("scripts.event_handler")

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
    -- TODO
end)

-- Save file created
-- Loaded save file what don`t contain mod
-- Can write in `global` and read `game`
event.on_init(function()
    -- Initialize libraries
    dictionary.init()
    on_tick_n.init()

    -- Initialize `global` table
    -- TODO
end)

-- Loaded save file what contains mod
-- Cant write in global
event.on_load(function()
    dictionary.load()
    -- Restore local vars from `global`
    -- Re-register event handlers
    -- TODO
end)

---------------------------------------------------------------------------
-- -- -- Mod events
---------------------------------------------------------------------------

gui.hook_events(event_handler.handle_gui_event)

event.register(
        {
            defines.events.on_built_entity,
            defines.events.on_robot_built_entity,
            -- TODO check
            defines.events.script_raised_built,
            defines.events.script_raised_revive,
            defines.events.on_entity_cloned
        },
        function(e) event_handler.build_depot_entity(e) end,
        {{ filter="name", name= automated_train_depot.constants.entity_names.depot_building }}
)

event.register(
        {
            defines.events.on_pre_player_mined_item,
            defines.events.on_robot_pre_mined,
            defines.events.on_entity_died,
            defines.events.script_raised_destroy,
        },
        function(e) event_handler.destroy_depot_entity(e) end,
        {{ filter="name", name= automated_train_depot.constants.entity_names.depot_building }}
)

event.register(defines.events.on_runtime_mod_setting_changed, function(e)
    event_handler.reload_settings(e)
end)

event.register(defines.events.on_gui_opened, event_handler.open_gui)