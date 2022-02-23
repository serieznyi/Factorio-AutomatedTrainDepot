local public = {}

public.on_nth_tick = {
    persistence_storage_gc = 18000, -- every 5 minute
    gui_pop_up = 1, -- every tick
    tasks_processor = 60, -- every second
    balance_trains_count = 120, -- every 2-nd second
    train_deploy = 5, -- every 5 tick
}

public.events = {
    on_train_task_changed_mod = script.generate_event_name(),
    on_train_template_deleted_mod = script.generate_event_name(),
    on_train_template_changed_mod = script.generate_event_name(),
}

public.train_template = {
}

public.train = {
    state = {
        execute_schedule        = "execute_schedule",
        go_to_depot             = "go_to_depot",
        go_to_cleaning_station  = "go_to_cleaning_station",
    },
    direction = {
        in_direction = "in_direction",
        opposite_direction = "opposite",
    }
}

public.prototypes = require("prototypes.defines.index")

public.gui = {
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
        change_carrier_direction = script.generate_event_name(),
        refresh_train_part = script.generate_event_name(),
        -- other
        trigger_form_changed = script.generate_event_name(),
        touch_form = script.generate_event_name(),
        enable_train_template = script.generate_event_name(),
        disable_train_template = script.generate_event_name(),
        open_uncontrolled_trains_map = script.generate_event_name(),
    },
    frames = {
        main = { name = "main_frame" },
        add_template = { name = "add_template_frame" },
        settings = { name = "settings_frame" },
    },
    components = {
        train_builder = { name = "train_builder_component" },
        train_template_view = { name = "train_template_view_component" },
        trains_map = { name = "trains_map_component" },
    },
    mod_frame_marker_name = "atd_frame",
}

public.persistence = {
    garbage_ttl = public.on_nth_tick.persistence_storage_gc,
}

return public