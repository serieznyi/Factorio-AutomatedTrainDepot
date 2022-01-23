local defines = {}

defines.events = {
    on_group_saved = script.generate_event_name(),
    on_form_changed = script.generate_event_name(),
}

defines.all_events = {
    defines.events.on_group_saved,
    defines.events.on_form_changed,
}

defines.remote_interfaces = {
    main_frame = "atd-main-frame",
    settings_frame = "atd-settings-frame",
    add_group_frame = "atd-add-group-frame",
}

defines.entity = require("prototypes.defines.entity")

defines.gui = {
    mod_frame_marker_name = "atd_frame",
}

return defines