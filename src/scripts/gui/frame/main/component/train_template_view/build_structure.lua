local mod_gui = require("scripts.util.gui")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param train_template atd.TrainTemplate
function private.build_train_template_name(train_template)
    local icon = mod_gui.image_for_item(train_template.icon)

    return icon .. " " .. train_template.name
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param train_template atd.TrainTemplate
function public.get(train_template)
    local train_template_name = private.build_train_template_name(train_template)

    return {
        type = "frame",
        direction = "vertical",
        ref = { "component" },
        tags = { train_template_id = train_template.id },
        children = {
            -- Titlebar
            {
                type = "flow",
            },
            -- Content
            {
                type = "flow",
                direction = "vertical",
                style_mods = {
                    vertically_stretchable = true,
                    horizontally_stretchable = true,
                },
                children = {
                    {
                        type = "flow",
                        children = {
                            {
                                type = "label",
                                caption = train_template_name,
                            },
                        }
                    },
                    {
                        type = "line",
                    },
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
                                caption = "-",
                            },
                            {
                                type = "textfield",
                                numeric = true,
                                lose_focus_on_confirm = true,
                                allow_decimal = false,
                                allow_negative = false,
                                text = train_template.amount,
                            },
                            {
                                type = "button",
                                style = "tool_button",
                                caption = "+",
                            },
                        }
                    },

                },
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
                            on_click = { target = mod.defines.gui.components.template_view.name, action = mod.defines.gui.actions.disable_train_template }
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
                            on_click = { target = mod.defines.gui.components.template_view.name, action = mod.defines.gui.actions.enable_train_template }
                        },
                    },
                }
            },
        }
    }
end

return public