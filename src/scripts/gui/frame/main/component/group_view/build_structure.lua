local mod_gui = require("scripts.util.gui")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param train_group atd.TrainGroup
function private.build_train_group_name(train_group)
    local icon = mod_gui.image_for_item(train_group.icon)

    return icon .. " " .. train_group.name
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param train_group atd.TrainGroup
function public.get(train_group)
    local train_group_name = private.build_train_group_name(train_group)

    return {
        type = "frame",
        direction = "vertical",
        ref = { "component" },
        tags = { train_group_id = train_group.id },
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
                                caption = train_group_name,
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
                                text = train_group.amount,
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
                        caption = {"train-group-view.atd-disable"},
                        ref = {"disable_button"},
                        enabled = train_group.enabled,
                        actions = {
                            on_click = { target = mod.defines.gui.components.group_view.name, action = mod.defines.gui.actions.disable_train_group }
                        },
                    },
                    {
                        type = "button",
                        style = "button",
                        caption = {"train-group-view.atd-enable"},
                        ref = {"enable_button"},
                        enabled = not train_group.enabled,
                        tags = { train_group_id = train_group.id },
                        actions = {
                            on_click = { target = mod.defines.gui.components.group_view.name, action = mod.defines.gui.actions.enable_train_group }
                        },
                    },
                }
            },
        }
    }
end

return public