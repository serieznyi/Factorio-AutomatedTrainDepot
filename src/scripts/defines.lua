local defines = {}

defines.task = {
    construct = {
        id = 1,
        state = {

        }
    },
}

defines.on_nth_tick = {
    persistence_storage_gc = 18000, -- every 5 minute
    gui_pop_up = 1, -- every 1 second
}

defines.events = {
    -- other
    on_train_template_saved_mod = script.generate_event_name(),
}

defines.train_template = {
}

defines.train = {
    state = {
        execute_schedule        = "execute_schedule",
        go_to_depot             = "go_to_depot",
        go_to_cleaning_station  = "go_to_cleaning_station",
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
        change_trains_quantity = script.generate_event_name(),
        -- train gui
        delete_train_part = script.generate_event_name(),
        change_locomotive_direction = script.generate_event_name(),
        refresh_train_part = script.generate_event_name(),
        -- other
        trigger_form_changed = script.generate_event_name(),
        touch_form = script.generate_event_name(),
        enable_train_template = script.generate_event_name(),
        disable_train_template = script.generate_event_name(),
        open_uncontrolled_trains_view = script.generate_event_name(),
    },
    frames = {
        main = { name = "main_frame" },
        add_template = { name = "add_template_frame" },
        settings = { name = "settings_frame" },
    },
    components = {
        train_builder = { name = "train_builder_component" },
        train_template_view = { name = "train_template_view_component" },
        trains_view = { name = "trains_view_component" },
    },
    mod_frame_marker_name = "atd_frame",
}

defines.persistence = {
    garbage_ttl = defines.on_nth_tick.persistence_storage_gc,
}

return defines