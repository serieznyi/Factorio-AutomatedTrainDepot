local event = require("__flib__.event")
local gui = require("__flib__.gui")

local default_controller = require("extra.logic.controllers.default_controller")

local filters_train_depot = {{ filter="name", name=modification_state.constants.entity_names.depot_building }}

event.register({
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
}, function(e)
    default_controller:on_build_entity(e)
end, filters_train_depot)

event.register({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
}, function(e)
    default_controller:on_deconstruct_entity(e)
end)

event.register(defines.events.on_runtime_mod_setting_changed, function(e)
    default_controller:on_runtime_mod_setting_changed(e)
end)

event.register(defines.events.on_gui_opened, function(e)
    default_controller:on_gui_opened(e)
end)