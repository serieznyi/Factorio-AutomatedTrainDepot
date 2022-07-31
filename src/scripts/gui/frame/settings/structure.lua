local FRAME = {
    NAME = mod.defines.gui.frames.settings.name,
}

local structure = {}

local label_info_sprite_style = {
    natural_width = 15,
    natural_height = 15,
}

function structure.get(settings)
    local new = settings == nil and true or false

    return {
        type = "frame",
        name = FRAME.NAME,
        tags = {type = mod.defines.gui.mod_frame_marker_name },
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
                                caption = {"settings-frame.atd-use-any-supported-fuel"},
                            },
                            {
                                type = "checkbox",
                                state = false,
                                ref = { "use_any_fuel_checkbox" },
                                actions = {
                                    on_checked_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form }
                                }
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
                                type = "flow",
                                direction = "horizontal",
                                style_mods = {
                                    vertically_squashable = true,
                                    horizontally_squashable = true,
                                },
                                children = {
                                    {
                                        type = "label",
                                        style = "caption_label",
                                        caption = {"settings-frame.atd-default-train-schedule"},
                                        tooltip = { "settings-frame-description.atd-default-train-schedule" },
                                    },
                                    {
                                        type = "sprite",
                                        sprite = "atd_sprite_info",
                                        resize_to_sprite = false,
                                        style_mods = label_info_sprite_style,
                                    },
                                }
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
                            on_click = { target = FRAME.NAME, action = mod.defines.gui.actions.close_frame },
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
                        caption = new and {"gui.atd-create"} or {"gui.atd-update"},
                        ref = {"submit_button"},
                        enabled = false,
                        actions = {
                            on_click = { target = FRAME.NAME, action = mod.defines.gui.actions.save_form },
                        },
                    },
                }
            },
        }
    }
end

return structure