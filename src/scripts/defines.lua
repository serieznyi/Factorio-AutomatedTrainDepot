local defines = {}

defines.events = {
    -- persistence
    on_group_added_persistence_mod = script.generate_event_name(),
    on_group_deleted_persistence_mod = script.generate_event_name(),
    -- other
    on_group_saved_mod = script.generate_event_name(),
    -- gui events
    on_gui_form_changed_mod = script.generate_event_name(),
    on_gui_group_selected_mod = script.generate_event_name(),
    on_gui_type_of_train_part_changed_mod = script.generate_event_name(),
}

defines.train_group = {
}

defines.train = {
    direction = {
        left = 1,
        right = 2,
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
        -- group
        delete_group = script.generate_event_name(),
        select_group = script.generate_event_name(),
        edit_group = script.generate_event_name(),
        -- train gui
        delete_train_part = script.generate_event_name(),
        change_locomotive_direction = script.generate_event_name(),
        refresh_train_part = script.generate_event_name(),
        -- other
        trigger_form_changed = script.generate_event_name(),
        enable_train_group = script.generate_event_name(),
        disable_train_group = script.generate_event_name(),
    },
    frames = {
        main = { name = "main_frame" },
        add_group = { name = "add_group_frame" },
        settings = { name = "settings_frame" },
    },
    components = {
      train_builder = { name = "train_builder_component" },
      group_view = { name = "group_view_component" },
    },
    mod_frame_marker_name = "atd_frame",
}

return defines