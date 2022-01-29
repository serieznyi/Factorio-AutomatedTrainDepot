local defines = {}

defines.events = {
    on_mod_group_saved = script.generate_event_name(),
    -- gui events
    on_mod_gui_form_changed = script.generate_event_name(),
    on_mod_gui_group_selected = script.generate_event_name(),
    on_mod_gui_type_of_train_part_changed = script.generate_event_name(),
}

defines.train_group = {
    state = {
        processed = 1,
        paused = 2,
    }
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
        start_build_train = script.generate_event_name(),
    },
    frames = {
        main = { name = "main_frame" },
        add_group = { name = "add_group_frame" },
        settings = { name = "settings_frame" },
    },
    components = {
      train_builder = { name = "train_builder_component" }
    },
    mod_frame_marker_name = "atd_frame",
}

return defines