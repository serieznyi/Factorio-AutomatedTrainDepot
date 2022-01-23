local defines = {}

defines.events = {
    on_mod_group_saved = script.generate_event_name(),
    -- gui events
    on_mod_gui_form_changed = script.generate_event_name(),
    on_mod_gui_group_selected = script.generate_event_name(),
    on_mod_gui_type_of_train_part_changed = script.generate_event_name(),
}

defines.entity = require("prototypes.defines.entity")

defines.gui = {
    actions = {
        -- common
        close_frame = script.generate_event_name(),
        save_form = script.generate_event_name(),
        -- group
        delete_group = script.generate_event_name(),
        -- train gui
        delete_train_part = script.generate_event_name(),
        change_locomotive_direction = script.generate_event_name(),
    },
    mod_frame_marker_name = "atd_frame",
}

return defines