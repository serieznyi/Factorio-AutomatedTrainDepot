local defines = {}

defines.events = {
    -- persistence
    on_template_added_persistence_mod = script.generate_event_name(),
    on_template_deleted_persistence_mod = script.generate_event_name(),
    -- other
    on_train_template_saved_mod = script.generate_event_name(),
    -- gui events
    on_gui_form_changed_mod = script.generate_event_name(),
    on_gui_train_template_selected_mod = script.generate_event_name(),
    on_gui_type_of_train_part_changed_mod = script.generate_event_name(),
}

defines.train_template = {
}

defines.train = {
    state = {
        execute_schedule        = "execute_schedule",
        go_to_depot             = "go_to_depot",
        go_to_cleaning_station  = "go_to_cleaning_station",
        leaves_depot            = "leaves_depot",
    },
    direction = {
        left = "left",
        right = "right",
    }
}

defines.entity = require("prototypes.defines.entity")

defines.gui = {
    actions = {
        any = script.generate_event_name(),
        -- common
        open_frame = script.generate_event_name(),
        close_frame = script.generate_event_name(),
        save_form = script.generate_event_name(),
        -- train template
        delete_train_template = script.generate_event_name(),
        select_train_template = script.generate_event_name(),
        edit_train_template = script.generate_event_name(),
        -- train gui
        delete_train_part = script.generate_event_name(),
        change_locomotive_direction = script.generate_event_name(),
        refresh_train_part = script.generate_event_name(),
        -- other
        trigger_form_changed = script.generate_event_name(),
        enable_train_template = script.generate_event_name(),
        disable_train_template = script.generate_event_name(),
    },
    frames = {
        main = { name = "main_frame" },
        add_template = { name = "add_template_frame" },
        settings = { name = "settings_frame" },
    },
    components = {
        train_builder = { name = "train_builder_component" },
        template_view = { name = "template_view_component" },
    },
    mod_frame_marker_name = "atd_frame",
}

return defines