local public = {}

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function public.get(train_template)
    local QUANTITY_ONE = 1
    local QUANTITY_FIVE = 5

    return {
        type = "frame",
        direction = "vertical",
        ref = { "train_template_container" },
        tags = { train_template_id = train_template.id },
        style_mods = {
            vertically_stretchable = true,
            horizontally_stretchable = true,
        },
        children = {
            -- Titlebar
            {
                type = "flow",
                direction = "vertical",
                children = {
                    {
                        type = "label",
                        ref = { "train_template_title_label" }
                    },
                    {
                        type = "line",
                    },
                }
            },
            -- Content
            {
                type = "flow",
                ref = { "content" },
                direction = "vertical",
                style_mods = {
                    vertically_stretchable = true,
                    horizontally_stretchable = true,
                },
                children = {
                    -- train view
                    {
                        type = "scroll-pane",
                        horizontal_scroll_policy = "auto",
                        vertical_scroll_policy = "never",
                        style_mods = {
                            bottom_padding = 20,
                        },
                        children = {
                            {
                                type = "flow",
                                direction = "horizontal",
                                ref = { "train_view" },
                            },
                        }
                    },
                    -- tasks
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {
                                type = "flow",
                                direction = "vertical",
                                style_mods = {
                                    vertically_stretchable = true,
                                    horizontally_stretchable = true,
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"train-template-view-component.atd-info"},
                                        style = "frame_title",
                                        ignored_by_interaction = true
                                    },
                                    {
                                        type = "frame",
                                        -- todo add info
                                    },
                                },
                            },
                            {
                                type = "line",
                                direction = "vertical",
                            },
                            -- form tasks
                            {
                                type = "flow",
                                direction = "vertical",
                                style_mods = {
                                    vertically_stretchable = true,
                                    horizontally_stretchable = true,
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"train-template-view-component.atd-form"},
                                        style = "frame_title",
                                        ignored_by_interaction = true
                                    },
                                    {
                                        type = "scroll-pane",
                                        horizontal_scroll_policy = "never",
                                        vertical_scroll_policy = "auto",
                                        ref = { "form_tasks_progress_container" },
                                    },
                                },
                            },
                            {
                                type = "line",
                                direction = "vertical",
                            },
                            -- disband tasks
                            {
                                type = "flow",
                                direction = "vertical",
                                style_mods = {
                                    vertically_stretchable = true,
                                    horizontally_stretchable = true,
                                },
                                children = {
                                    {
                                        type = "label",
                                        caption = {"train-template-view-component.atd-disband"},
                                        style = "frame_title",
                                        ignored_by_interaction = true
                                    },
                                    {
                                        type = "scroll-pane",
                                        horizontal_scroll_policy = "never",
                                        vertical_scroll_policy = "auto",
                                        ref = { "disband_tasks_progress_container" },
                                    },
                                },
                            },
                        },
                    }
                }
            },
            -- Bottom control bar
            {
                type = "flow",
                style = "dialog_buttons_horizontal_flow",
                direction = "horizontal",
                ref = {"footerbar_flow"},
                children = {
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "-" .. QUANTITY_ONE,
                                tooltip = { "train-template-view-component.atd-decrease-trains-count-button-tooltip", QUANTITY_ONE },
                                actions = {
                                    on_click = { event = atd.defines.events.on_gui_trains_quantity_changed, count = QUANTITY_ONE * -1 }
                                },
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "-" .. QUANTITY_FIVE,
                                tooltip = { "train-template-view-component.atd-decrease-trains-count-button-tooltip", QUANTITY_FIVE },
                                actions = {
                                    on_click = { event = atd.defines.events.on_gui_trains_quantity_changed, count = QUANTITY_FIVE * -1 }
                                },
                            },
                            {
                                type = "textfield",
                                numeric = true,
                                lose_focus_on_confirm = true,
                                enabled = false,
                                style = "atd_trains_quantity_textfield",
                                allow_decimal = false,
                                allow_negative = false,
                                text = train_template.trains_quantity,
                                ref = {"trains_quantity"},
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "+" .. QUANTITY_FIVE,
                                tooltip = { "train-template-view-component.atd-increase-trains-count-button-tooltip", QUANTITY_FIVE },
                                actions = {
                                    on_click = { event = atd.defines.events.on_gui_trains_quantity_changed, count = QUANTITY_FIVE }
                                },
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "+" .. QUANTITY_ONE,
                                tooltip = { "train-template-view-component.atd-increase-trains-count-button-tooltip", QUANTITY_ONE },
                                actions = {
                                    on_click = { event = atd.defines.events.on_gui_trains_quantity_changed, count = QUANTITY_ONE }
                                },
                            },
                        }
                    },
                    {
                        type = "empty-widget",
                        ignored_by_interaction = true,
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                    },
                    {
                        type = "button",
                        style = "button",
                        caption = {"train-template-view-component.atd-pause-button"},
                        tooltip = {"train-template-view-component.atd-pause-button-tooltip"},
                        ref = {"disable_button"},
                        enabled = train_template.enabled,
                        actions = {
                            on_click = { event = atd.defines.events.on_gui_train_template_disabled }
                        },
                    },
                    {
                        type = "button",
                        style = "button",
                        caption = {"train-template-view-component.atd-enable-button"},
                        tooltip = {"train-template-view-component.atd-enable-button-tooltip"},
                        ref = {"enable_button"},
                        enabled = not train_template.enabled,
                        tags = { train_template_id = train_template.id },
                        actions = {
                            on_click = { event = atd.defines.events.on_gui_train_template_enabled }
                        },
                    },
                }
            },
        }
    }
end

return public