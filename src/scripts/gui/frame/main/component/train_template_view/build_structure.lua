local mod_gui = require("scripts.util.gui")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param train_template scripts.lib.domain.TrainTemplate
function public.get(train_template)
    return {
        type = "frame",
        direction = "vertical",
        ref = { "component" },
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
                        ref = { "component_title_label" }
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
                    {
                        type = "flow",
                        direction = "horizontal",
                        ref = { "train_view" },
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        children = {
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "-1",
                                actions = {
                                    on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.change_trains_quantity, count = -1 }
                                },
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "-5",
                                actions = {
                                    on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.change_trains_quantity, count = -5 }
                                },
                            },
                            {
                                type = "textfield",
                                numeric = true,
                                lose_focus_on_confirm = true,
                                allow_decimal = false,
                                allow_negative = false,
                                text = train_template.trains_quantity,
                                ref = {"trains_quantity"},
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "+5",
                                actions = {
                                    on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.change_trains_quantity, count = 5 }
                                },
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "+1",
                                actions = {
                                    on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.change_trains_quantity, count = 1 }
                                },
                            },
                        }
                    },
                    {
                        type = "flow",
                        direction = "horizontal",
                        ref = { "tasks_progress_container" },
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
                        type = "empty-widget",
                        ignored_by_interaction = true,
                        style_mods = {
                            horizontally_stretchable = true,
                        },
                    },
                    {
                        type = "button",
                        style = "button",
                        caption = {"train-template-view-component.atd-disable-button"},
                        tooltip = {"train-template-view-component.atd-disable-button-tooltip"},
                        ref = {"disable_button"},
                        enabled = train_template.enabled,
                        actions = {
                            on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.disable_train_template }
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
                            on_click = { target = mod.defines.gui.components.train_template_view.name, action = mod.defines.gui.actions.enable_train_template }
                        },
                    },
                }
            },
        }
    }
end

return public