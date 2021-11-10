modificationState = require("extra.logic.init_modification_state")

-- TODO
--script.on_nth_tick(, function()
--
--end)

-- Game version changed
-- Any mod version changed
-- Any mod added
-- Any mod removed
-- Any mod prototypes changed
-- Any mod settings changed
script.on_configuration_changed(function()
-- TODO
end)

-- Save file created
-- Loaded save file what don`t contain us
-- Can write in `global` and read `game`
script.on_init(function()
    -- Init local vars
    -- TODO
end)

-- Loaded save file what contains us
-- Cant write in global
script.on_load(function()
    -- Restore local vars from `global`
    -- Re-register event handlers
    -- TODO
end)

require('extra.logic.register_event_handlers')