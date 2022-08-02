local structure = {}

function structure.get(config)
    return {
        type = "frame",
        name = config.frame_name,
        tags = {atd_frame = true },
        direction = "vertical",
        ref  =  {"window"},
        visible = false,
        style_mods = {
            natural_width = config.width,
            natural_height = config.height,
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
                        caption = {"main-frame.atd-title"},
                        ignored_by_interaction = true
                    },
                    {
                        type = "empty-widget",
                        style = "flib_titlebar_drag_handle",
                        ignored_by_interaction = true
                    },
                    {
                        type = "sprite-button",
                        name = "frame_settings_button",
                        style = "frame_action_button",
                        tooltip = {"main-frame.atd-open-settings"},
                        sprite = "atd_sprite_settings",
                        actions = {
                            on_click = { event = mod.defines.events.on_gui_open_settings_frame_click }
                        }
                    },
                    {
                        type = "sprite-button",
                        name = "frame_close_button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        tooltip = {"gui.atd-close-window"},
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        actions = {
                            on_click = { event = mod.defines.events.on_gui_close_main_frame_click }
                        }
                    },
                }
            },
            -- Content
            {
                type = "tabbed-pane",
                style_mods = {
                    horizontally_stretchable = true,
                    vertically_stretchable = true,
                },
                children = {
                    {
                        tab = {
                            type = "tab",
                            caption = {"main-frame.atd-tab-train-template"},
                        },
                        content = {
                            type = "frame",
                            style = "inside_deep_frame",
                            style_mods = {
                                horizontally_stretchable = true,
                                vertically_stretchable = true,
                            },
                            children = {
                                {
                                    type = "flow",
                                    direction = "horizontal",
                                    children = {
                                        {
                                            type = "flow",
                                            direction = "vertical",
                                            style_mods = {
                                                natural_width = config.width * 0.25,
                                            },
                                            children = {
                                                {
                                                    type = "frame",
                                                    style = "inside_deep_frame",
                                                    children = {
                                                        {
                                                            type = "frame",
                                                            style = "subheader_frame",
                                                            style_mods = {
                                                                horizontally_stretchable = true,
                                                            },
                                                            children = {
                                                                {
                                                                    type = "sprite-button",
                                                                    style = "tool_button_green",
                                                                    tooltip = {"main-frame.atd-add-new-train-template"},
                                                                    sprite = "atd_sprite_add",
                                                                    actions = {
                                                                        on_click = { event = mod.defines.events.on_gui_open_adding_template_frame_click }
                                                                    },
                                                                },
                                                                {
                                                                    type = "sprite-button",
                                                                    style = "tool_button",
                                                                    tooltip = {"main-frame.atd-edit-train-template"},
                                                                    ref = {"edit_button"},
                                                                    sprite = "atd_sprite_edit",
                                                                    enabled = false,
                                                                    actions = {
                                                                        on_click = { event = mod.defines.events.on_gui_open_editing_template_frame_click }
                                                                    },
                                                                },
                                                                {
                                                                    type = "sprite-button",
                                                                    style = "tool_button_red",
                                                                    tooltip = {"main-frame.atd-delete-template"},
                                                                    ref = {"delete_button"},
                                                                    sprite = "atd_sprite_trash",
                                                                    enabled = false,
                                                                    actions = {
                                                                        on_click = { event = mod.defines.events.on_gui_delete_train_template_click }
                                                                    },
                                                                },
                                                            }
                                                        },
                                                    }
                                                },
                                                {
                                                    type = "flow",
                                                    direction = "vertical",
                                                    ref = {"trains_templates_list_container"},
                                                },
                                            }
                                        },
                                        {
                                            type = "flow",
                                            style_mods = {
                                                natural_width = config.width - (config.width * 0.25),
                                            },
                                            direction = "vertical",
                                            children = {
                                                {
                                                    type = "frame",
                                                    style_mods = {
                                                        horizontally_stretchable = true,
                                                        vertically_stretchable = true,
                                                    },
                                                    ref = {"trains_templates_view"},
                                                    style = "inside_deep_frame",
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    },
                    {
                        tab = {
                            type = "tab",
                            caption = {"main-frame.atd-tab-map"},
                            actions = {
                                on_click = { event = mod.defines.events.on_gui_open_uncontrolled_trains_map_click }
                            }
                        },
                        content = {
                            type = "frame",
                            style = "inside_deep_frame",
                            style_mods = {
                                horizontally_stretchable = true,
                                vertically_stretchable = true,
                            },
                            ref = {"trains_map_view"}
                        }
                    }
                }
            },
        }
    }
end

return structure