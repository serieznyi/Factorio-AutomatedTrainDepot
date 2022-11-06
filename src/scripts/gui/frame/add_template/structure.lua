local structure = {}

function structure.get(config)
    ---@type scripts.lib.domain.entity.template.TrainTemplate
    local train_template = config.train_template
    local new = train_template == nil
    local train_template_id = train_template ~= nil and train_template.id or nil
    local train_template_name = train_template ~= nil and train_template.name or nil

    return {
        type = "frame",
        name = config.frame_name,
        tags = { atd_frame = true, train_template_id = train_template_id },
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
                        caption = new and {"add-train-template-frame.atd-add-title"} or { "add-train-template-frame.atd-edit-title", train_template_name },
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
                        type = "table",
                        vertical_centering = false,
                        column_count = 2,
                        children = {
                            -- ICON
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-icon" },
                            },
                            {
                                type = "flow",
                                style_mods = {
                                    bottom_padding = 15,
                                },
                                children = {
                                    {
                                        type = "choose-elem-button",
                                        ref = {"icon_input"},
                                        elem_type = "item",
                                        actions = {
                                            on_elem_changed = { event = atd.defines.events.on_gui_adding_template_frame_changed }
                                        }
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        tags = {validation_errors_container = true},
                                    }
                                }
                            },
                            -- NAME
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-name" },
                            },
                            {
                                type = "flow",
                                direction = "vertical",
                                style_mods = {
                                    bottom_padding = 15,
                                },
                                children = {
                                    {
                                        type = "textfield",
                                        ref = {"name_input"},
                                        actions = {
                                            on_text_changed = { event = atd.defines.events.on_gui_adding_template_frame_changed },
                                            on_confirmed = { event = atd.defines.events.on_gui_adding_template_frame_changed },
                                        }
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        tags = {validation_errors_container = true},
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        children = {
                                            {
                                                type = "label",
                                                caption = { "add-train-template-frame.atd-name-rick-text" },
                                                tooltip = { "add-train-template-frame-description.atd-name-rick-text" },
                                            },
                                            {
                                                type = "flow",
                                                direction = "horizontal",
                                                children = {
                                                    {
                                                        type = "choose-elem-button",
                                                        ref = {"name_rich_text_chooser_signal"},
                                                        elem_type = "signal",
                                                        actions = {
                                                            on_elem_changed = { event = atd.defines.events.on_gui_name_rich_text_changed }
                                                        }
                                                    },
                                                    {
                                                        type = "choose-elem-button",
                                                        ref = {"name_rich_text_chooser_recipe"},
                                                        elem_type = "recipe",
                                                        actions = {
                                                            on_elem_changed = { event = atd.defines.events.on_gui_name_rich_text_changed }
                                                        }
                                                    },
                                                }
                                            }
                                        },
                                    }
                                }
                            },
                            -- TRAIN
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-train" },
                            },
                            {
                                type = "flow",
                                style_mods = {
                                    bottom_padding = 15,
                                },
                                children = {
                                    {
                                        type = "frame",
                                        direction = "horizontal",
                                        ref  =  {"train_builder_container"},
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        tags = {validation_errors_container = true},
                                    }
                                }
                            },
                            -- FUEL
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-fuel" },
                            },
                            {
                                type = "choose-elem-button",
                                ref = {"train_fuel_chooser"},
                                elem_type = "item",
                                elem_filters = {
                                    { filter="fuel-category", ["fuel-category"] = "chemical" }
                                },
                                actions = {
                                    on_elem_changed = { event = atd.defines.events.on_gui_adding_template_frame_changed }
                                }

                            },
                            {
                                type = "label",
                                caption = "",
                            },
                            {
                                type = "flow",
                                direction = "horizontal",
                                children = {
                                    {
                                        type = "label",
                                        caption = {"add-train-template-frame.atd-use-any-supported-fuel"},
                                    },
                                    {
                                        type = "checkbox",
                                        state = false,
                                        ref = { "use_any_fuel_checkbox" },
                                        actions = {
                                            on_checked_state_changed = { event = atd.defines.events.on_gui_adding_template_frame_changed }
                                        }
                                    },
                                },
                            },
                            -- CLEAN STATION
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-clean-train-station" },
                                tooltip = { "add-train-template-frame-description.atd-clean-train-station" },
                            },
                            {
                                type = "flow",
                                style_mods = {
                                    bottom_padding = 15,
                                },
                                children = {
                                    {
                                        type = "flow",
                                        ref  =  {"clean_train_station_dropdown_wrapper"},
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        tags = {validation_errors_container = true},
                                    }
                                }
                            },
                            {
                                type = "textfield",
                                ref = { "trains_quantity" },
                                visible = false,
                            },
                            -- TRAIN SCHEDULE
                            {
                                type = "label",
                                caption = { "add-train-template-frame.atd-working-schedule" },
                                tooltip = { "add-train-template-frame-description.atd-working-schedule" },
                            },
                            {
                                type = "flow",
                                style_mods = {
                                    bottom_padding = 15,
                                },
                                children = {
                                    {
                                        type = "flow",
                                        ref  =  {"destination_schedule_dropdown_wrapper"},
                                    },
                                    {
                                        type = "flow",
                                        direction = "vertical",
                                        tags = {validation_errors_container = true},
                                    }
                                }
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
                            on_click = { event = atd.defines.events.on_gui_close_add_template_frame_click },
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
                            on_click = { event = atd.defines.events.on_gui_save_adding_template_frame_click },
                        },
                    },
                }
            },
        }
    }
end

return structure