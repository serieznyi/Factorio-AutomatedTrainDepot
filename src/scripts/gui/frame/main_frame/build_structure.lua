local constants = require("scripts.gui.frame.main_frame.constants")

local FRAME_NAME = constants.FRAME_NAME

local FRAME_WIDTH = constants.FRAME_WIDTH
local FRAME_HEIGHT = constants.FRAME_HEIGHT

local ACTION = constants.ACTION

local build_structure = {}

function build_structure.get()
    return {
        type = "frame",
        name = FRAME_NAME,
        direction = "vertical",
        ref  =  {"window"},
        visible = false,
        style_mods = {
            natural_width = FRAME_WIDTH,
            natural_height = FRAME_HEIGHT,
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
                        style = "frame_action_button",
                        sprite = "atd_sprite_settings",
                        actions = {
                            on_click = {
                                gui = automated_train_depot.constants.gui.frame_names.settings_frame,
                                action = automated_train_depot.constants.gui.common_actions.open
                            }
                        }
                    },
                    {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        actions = {
                            on_click = {gui = FRAME_NAME, action = ACTION.CLOSE}
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
                            minimal_width = FRAME_WIDTH * 0.25,
                            maximal_width = FRAME_WIDTH * 0.25,
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
                                                tooltip = {"main-frame.atd-add-new-group"},
                                                sprite = "atd_sprite_add",
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.add_group_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.open,
                                                    },
                                                },
                                            },
                                            {
                                                type = "sprite-button",
                                                style = "tool_button",
                                                tooltip = {"main-frame.atd-edit-group"},
                                                ref = {"edit_group_button"},
                                                sprite = "atd_sprite_edit",
                                                enabled = false,
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.add_group_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.edit,
                                                    },
                                                },
                                            },
                                            {
                                                type = "sprite-button",
                                                style = "tool_button_red",
                                                tooltip = {"main-frame.atd-delete-group"},
                                                ref = {"delete_group_button"},
                                                sprite = "atd_sprite_trash",
                                                enabled = false,
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.main_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.delete,
                                                    },
                                                },
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
                            minimal_width = FRAME_WIDTH - (FRAME_WIDTH * 0.25),
                            maximal_width = FRAME_WIDTH - (FRAME_WIDTH * 0.25),
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