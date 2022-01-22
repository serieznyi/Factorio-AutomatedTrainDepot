local constants = {}

constants.modification_name = "AutomatedTrainDepot"

constants.gui = {
    frame_type_name = "atd_frame"
}

constants.remote_interfaces = {
    main_frame = "atd-main-frame",
    settings_frame = "atd-settings-frame",
    add_group_frame = "atd-add-group-frame",
}

constants.entity_names = {
    depot_building = "atd-building",
    depot_building_input = "atd-building-input",
    depot_building_output = "atd-building-output",
    depot_building_train_stop_input = "atd-building-train-stop-input",
    depot_building_train_stop_output = "atd-building-train-stop-output",
}

constants.gui = {
    common_actions = {
        open = "open",
    },
    frame_names = {
        main_frame = "main_frame",
        settings_frame = "settings_frame",
        add_group_frame = "add_group_frame",
    }
}

return constants