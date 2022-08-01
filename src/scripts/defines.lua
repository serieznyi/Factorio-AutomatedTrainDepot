local public = {}

local TICKS_PER_SECOND = 60

public.color = {
    orange = {r = 1, g = 0.45, b = 0, a = 0.75},
    red = {r = 1, g = 0, b = 0, a = 0.75},
    write = {r = 1, g = 1, b = 1, a = 1},
}

public.time_in_ticks = {
    seconds_5 = TICKS_PER_SECOND * 5,
}

public.on_nth_tick = {
    persistence_storage_gc = 18000, -- every 5 minute
    gui_pop_up = 1, -- every tick
    tasks_processor = 60, -- every second
    balance_trains_count = 120, -- every 2-nd second
    train_deploy = 5, -- every 5 tick
}

public.events = {
    on_core_train_task_changed = script.generate_event_name(),
    on_core_train_template_changed = script.generate_event_name(),
    on_core_settings_changed = script.generate_event_name(),
    -- component : train builder
    on_gui_choose_train_part = script.generate_event_name(),
    on_gui_delete_train_part_click = script.generate_event_name(),
    on_gui_change_carrier_direction_click = script.generate_event_name(),
    -- main frame
    on_gui_close_main_frame_click = script.generate_event_name(),
    on_gui_open_settings_frame_click = script.generate_event_name(),
    on_gui_open_adding_template_frame_click = script.generate_event_name(),
    on_gui_open_editing_template_frame_click = script.generate_event_name(),
    on_gui_delete_train_template_click = script.generate_event_name(),
    on_gui_open_uncontrolled_trains_map_click = script.generate_event_name(),
    -- main frame : train templates view
    on_gui_train_template_enabled = script.generate_event_name(),
    on_gui_train_template_disabled = script.generate_event_name(),
    on_gui_trains_quantity_changed = script.generate_event_name(),
    -- settings frame
    on_gui_settings_frame_changed = script.generate_event_name(),
    on_gui_settings_frame_close_click = script.generate_event_name(),
    on_gui_settings_frame_save_click = script.generate_event_name(),
    -- add template frame
    on_gui_adding_template_frame_changed = script.generate_event_name(),
    on_gui_close_add_template_frame_click = script.generate_event_name(),
    on_gui_save_adding_template_frame_click = script.generate_event_name(),
    --
    on_gui_extended_list_box_item_selected = script.generate_event_name(),
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
        choose_list_box_item = script.generate_event_name(),
        --
        close_main_frame = script.generate_event_name(),
        open_settings_frame = script.generate_event_name(),
        open_adding_template_frame = script.generate_event_name(),
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