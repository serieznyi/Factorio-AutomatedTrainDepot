local defines = {}

defines.events = {
    on_group_saved = script.generate_event_name(),
    on_form_changed = script.generate_event_name(),
}

defines.remote_interfaces = {
    main_frame = "atd-main-frame",
    settings_frame = "atd-settings-frame",
    add_group_frame = "atd-add-group-frame",
}

defines.entity = {
    depot_building = {
        name = "atd-building",
    },
    depot_building_input = {
        name = "atd-building-input",
    },
    depot_building_output = {
        name = "atd-building-output",
    },
    depot_building_train_stop_input = {
        name = "atd-building-train-stop-input",
    },
    depot_building_train_stop_output = {
        name = "atd-building-train-stop-output",
    },
}

defines.gui = {
    mod_frame_marker_name = "atd_frame",
}

return defines