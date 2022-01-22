local constants = require("scripts.gui.frame.add_group.constants")

local FRAME = constants.FRAME
local ACTION = constants.ACTION

local build_structure = {}

function build_structure.get()
    return {
        type = "frame",
        name = FRAME.NAME,
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
                        caption = {"add-group-frame.atd-title"},
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
                        column_count = 2,
                        children = {
                            {
                                type = "label",
                                caption = "Group icon",
                            },
                            {
                                type = "choose-elem-button",
                                ref = {"group_icon_input"},
                                elem_type = "item",
                                actions = {
                                    on_elem_changed = { gui = FRAME.NAME, action = ACTION.FORM_CHANGED }
                                }
                            },
                            {
                                type = "label",
                                caption = "Group name",
                            },
                            {
                                type = "textfield",
                                ref = {"group_name_input"},
                                actions = {
                                    on_text_changed = { gui = FRAME.NAME, action = ACTION.FORM_CHANGED },
                                    on_confirmed = { gui = FRAME.NAME, action = ACTION.FORM_CHANGED },
                                }
                            },
                            {
                                type = "label",
                                caption = "Train",
                            },
                            {
                                type = "frame",
                                direction = "horizontal",
                                ref  =  {"train_builder_container"},
                            }
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
                        caption = "Cancel",
                        actions = {
                            on_click = { gui = FRAME.NAME, action = ACTION.CLOSE },
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
                        caption = "Create",
                        ref = {"submit_button"},
                        enabled = false,
                        actions = {
                            on_click = { gui = FRAME.NAME, action = ACTION.SAVE },
                        },
                    },
                }
            },
        }
    }
end

return build_structure