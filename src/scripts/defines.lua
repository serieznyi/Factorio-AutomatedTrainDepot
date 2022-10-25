local defines = {}

local TICKS_PER_SECOND = 60
local TIME_1_SECOND = 60
local TIME_2_SECOND = 120
local TIME_1_MINUTE = 3600
local TIME_5_MINUTE = 18000

defines.color = {
    orange = {r = 1, g = 0.45, b = 0, a = 0.75},
    red = {r = 1, g = 0, b = 0, a = 0.75},
    white = { r = 1, g = 1, b = 1, a = 1},
}

defines.time_in_ticks = {
    seconds_1 = TICKS_PER_SECOND * 1,
    seconds_2 = TICKS_PER_SECOND * 2,
    seconds_5 = TICKS_PER_SECOND * 5,
}

defines.on_nth_tick = {
    persistence_storage_gc = TIME_1_MINUTE,
    balance_trains_count = TIME_2_SECOND,
    trains_manipulations = 10,
    trains_deploy = 5,
}

defines.events = {
    on_core_train_task_changed = script.generate_event_name(),
    on_core_train_task_deleted = script.generate_event_name(),
    on_core_train_task_added = script.generate_event_name(),
    on_core_train_template_changed = script.generate_event_name(),
    on_core_settings_changed = script.generate_event_name(),
    on_core_train_changed = script.generate_event_name(),
    on_core_depot_building_removed = script.generate_event_name(),
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
    on_gui_copy_train_template_click = script.generate_event_name(),
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
    on_gui_name_rich_text_changed = script.generate_event_name(),
    on_gui_close_add_template_frame_click = script.generate_event_name(),
    on_gui_save_adding_template_frame_click = script.generate_event_name(),
    --
    on_gui_extended_list_box_item_selected = script.generate_event_name(),
    on_gui_trains_station_selector_changed = script.generate_event_name(),
    on_gui_train_schedule_selector_changed = script.generate_event_name(),
    on_gui_background_dimmer_click = script.generate_event_name(),
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
        in_direction = "in_direction",
        opposite_direction = "opposite",
    }
}

defines.prototypes = require("prototypes.defines.index")

defines.persistence = {
    garbage_ttl = defines.on_nth_tick.persistence_storage_gc,
}

return defines