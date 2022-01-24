local constants = require("scripts.gui.frame.main.constants")

local FRAME = constants.FRAME

local build_structure = {}

function build_structure.get()
    return {
        type = "frame",
        name = FRAME.NAME,
        tags = {type = mod.defines.gui.mod_frame_marker_name },
        direction = "vertical",
        ref  =  {"window"},
        visible = false,
        style_mods = {
            natural_width = FRAME.WIDTH,
            natural_height = FRAME.HEIGHT,
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
                        sprite = "atd_sprite_settings",
                        actions = {
                            -- todo use name from defines
                            on_click = { target = "settings_frame", action = mod.defines.gui.actions.open_frame }
                        }
                    },
                    {
                        type = "sprite-button",
                        name = "frame_close_button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        actions = {
                            on_click = {target = FRAME.NAME, action = mod.defines.gui.actions.close_frame}
                        }
                    },
                }
            },
            -- Content
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "flow",
                        direction = "vertical",
                        style_mods = {
                            minimal_width = FRAME.WIDTH * 0.25,
                            maximal_width = FRAME.WIDTH * 0.25,
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
                                                name = "add_new_group_button",
                                                style = "tool_button_green",
                                                tooltip = {"main-frame.atd-add-new-group"},
                                                sprite = "atd_sprite_add",
                                                actions = {
                                                    -- todo use name from defines
                                                    on_click = { target = "add_group_frame", action = mod.defines.gui.actions.open_frame }
                                                },
                                            },
                                            {
                                                type = "sprite-button",
                                                name = "edit_group_button",
                                                style = "tool_button",
                                                tooltip = {"main-frame.atd-edit-group"},
                                                ref = {"edit_group_button"},
                                                sprite = "atd_sprite_edit",
                                                enabled = false,
                                                actions = {},
                                            },
                                            {
                                                type = "sprite-button",
                                                name = "delete_group_button",
                                                style = "tool_button_red",
                                                tooltip = {"main-frame.atd-delete-group"},
                                                ref = {"delete_group_button"},
                                                sprite = "atd_sprite_trash",
                                                enabled = false,
                                                actions = {},
                                            },
                                        }
                                    },
                                }
                            },
                            {
                                type = "flow",
                                direction = "vertical",
                                children = {
                                    {
                                        type = "frame",
                                        style = "inside_deep_frame",
                                        children = {
                                            {
                                                type = "scroll-pane",
                                                ref = {"groups_container"},
                                                style_mods = {
                                                    vertically_stretchable = true,
                                                    horizontally_stretchable = true,
                                                },
                                                style = "atd_scroll_pane_list_box",
                                            }
                                        }
                                    },
                                }
                            },
                        }
                    },
                    {
                        type = "flow",
                        style_mods = {
                            minimal_width = FRAME.WIDTH - (FRAME.WIDTH * 0.25),
                            maximal_width = FRAME.WIDTH - (FRAME.WIDTH * 0.25),
                        },
                        direction = "vertical",
                        children = {
                            {
                                type = "frame",
                                style_mods = {
                                    horizontally_stretchable = true,
                                    vertically_stretchable = true,
                                },
                                ref = {"content_frame"},
                                style = "inside_deep_frame",
                            }
                        }
                    }
                }
            }
        }
    }
end

return build_structure