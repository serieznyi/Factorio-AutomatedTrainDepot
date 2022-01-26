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
        -- Titlebar
        {
            type = "flow",
        },
        -- Content
        {
            type = "flow",
            direction = "vertical",
            ref = { "component" },
            tags = { train_group_id = train_group.id },
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
                }
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
                    caption = {"train-group-view.atd-pause"},
                    ref = {"pause_button"},
                    enabled = false,
                    actions = {},
                },
                {
                    type = "button",
                    style = "button",
                    caption = {"train-group-view.atd-start"},
                    ref = {"start_button"},
                    enabled = false,
                    actions = {},
                },
            }
        },
    }
end

return public