local structure = {}

function structure.get(config)
    return {
        type = "frame",
        name = config.frame_name,
        tags = { atd_frame = true },
        direction = "vertical",
        ref  =  {"window"},
        style_mods = {
            minimal_width = 600,
            minimal_height = 400,
            vertically_stretchable = true,
            horizontally_stretchable = true,
        },
        children = {
            -- Titlebar
            {
                type = "flow",
                style = "flib_titlebar_flow",
                ref = {"titlebar_flow"},
                children = {
                    {
                        type = "label",
                        style = "frame_title",
                        caption = {"settings-frame.atd-title"},
                        ignored_by_interaction = true
                    },
                    {
                        type = "empty-widget",
                        style = "flib_titlebar_drag_handle",
                        ignored_by_interaction = true
                    },
                }
            },
            -- Content
            {
                type = "frame",
                style = "inside_shallow_frame_with_padding",
                style_mods = {
                    horizontally_stretchable = true,
                    vertically_stretchable = true,
                },
                direction = "vertical",
                children = {
                    {
                        type = "frame",
                        style = "bordered_frame",
                        direction = "vertical",
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                        children = {
                            {
                                type = "label",
                                style = "caption_label",
                                caption = {"settings-frame.atd-default-fuel"},
                                tooltip = {"settings-frame-description.atd-default-fuel"},
                            },
                            {
                                type = "flow",
                                direction = "vertical",
                                children = {
                                    {
                                        type = "choose-elem-button",
                                        ref = {"train_fuel_chooser"},
                                        elem_type = "item",
                                        elem_filters = {
                                            { filter="fuel" },
                                            { filter="burnt-result", mode = "and", invert = true },
                                        },
                                        actions = {
                                            on_elem_changed = { event = mod.defines.events.on_gui_settings_frame_changed }
                                        }
                                    },
                                    {
                                        type = "flow",
                                        direction = "horizontal",
                                        children = {
                                            {
                                                type = "label",
                                                caption = {"settings-frame.atd-use-any-supported-fuel"},
                                                tooltip = {"settings-frame-description.atd-use-any-supported-fuel"},
                                            },
                                            {
                                                type = "checkbox",
                                                state = false,
                                                ref = { "use_any_fuel_checkbox" },
                                                actions = {
                                                    on_checked_state_changed = { event = mod.defines.events.on_gui_settings_frame_changed }
                                                }
                                            },
                                        },
                                    },
                                },
                            },
                        },
                    },
                    {
                        type = "frame",
                        style = "bordered_frame",
                        direction = "vertical",
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                        children = {
                            {
                                type = "label",
                                style = "caption_label",
                                caption = {"settings-frame.atd-default-clean-train-station"},
                                tooltip = { "settings-frame-description.atd-default-clean-train-station" },
                            },
                            {
                                type = "flow",
                                ref = { "clean_train_station_dropdown_wrapper" },
                            },
                        }
                    },
                    {
                        type = "frame",
                        style = "bordered_frame",
                        direction = "vertical",
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                        children = {
                            {
                                type = "label",
                                style = "caption_label",
                                caption = {"settings-frame.atd-default-train-schedule"},
                                tooltip = { "settings-frame-description.atd-default-train-schedule" },
                            },
                            {
                                type = "flow",
                                ref = { "target_train_station_dropdown_wrapper" },
                            },
                        }
                    },
                    {
                        type = "flow",
                        ref = {"validation_errors_container"},
                        direction = "vertical",
                    }
                }
            },
            -- Bottom control bar
            {
                type = "flow",
                style = "dialog_buttons_horizontal_flow",
                ref = {"footerbar_flow"},
                children = {
                    {
                        type = "button",
                        style = "back_button",
                        caption = { "gui.atd-cancel" },
                        actions = {
                            on_click = { event = mod.defines.events.on_gui_settings_frame_close_click },
                        },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_dialog_footer_drag_handle",
                        ignored_by_interaction = true
                    },
                    {
                        type = "button",
                        style = "confirm_button",
                        caption = {"gui.atd-update"},
                        ref = {"submit_button"},
                        enabled = false,
                        actions = {
                            on_click = { event = mod.defines.events.on_gui_settings_frame_save_click },
                        },
                    },
                }
            },
        }
    }
end

return structure