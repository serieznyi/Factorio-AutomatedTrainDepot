local flib_gui = require("__flib__.gui")

local frame = {}

local NAME = "main_frame"

function frame.get_name()
    return NAME
end

function frame.init()
    global.gui[NAME] = {}
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.create(player, entity)
    local refs = flib_gui.build(player.gui.screen, {
        {
            type = "frame",
            name = "depot_main_frame",
            direction = "vertical",
            ref  =  {"window"},
            style_mods = {
                natural_width = 1200,
                natural_height = 400,
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
                            caption = {"gui-name.automated-train-depot-main-frame"},
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
                            sprite = "utility/close_white",
                            hovered_sprite = "utility/close_black",
                            clicked_sprite = "utility/close_black",
                            ref = {"titlebar", "close_button"},
                            actions = {
                                on_click = {gui = "main_frame", action = "close"}
                            }
                        }
                    }
                },
                -- Content
                {
                    type = "frame",
                    style = "inside_shallow_frame_with_padding",
                    direction = "horizontal",
                    children = {
                        {
                            type = "button",
                            caption = "add",
                            actions = {
                                on_click = { gui = "add_group_frame", action = "create" },
                            },
                        },
                        {
                            type = "frame",
                            name = "groups_container",
                            style_mods = {
                                maximal_width = 400, -- todo use var
                            },
                            --style = "inside_shallow_frame_with_padding",
                            direction = "vertical",
                            children = {
                                {
                                    type = "list-box",
                                    items = {
                                        "asd1",
                                        "asd2",
                                    }
                                }
                            }
                        },
                        {
                            type = "frame",
                            name = "group_view",
                            --style = "inside_shallow_frame_with_padding",
                            direction = "vertical",
                            children = {
                                {
                                    type = "tabbed-pane",
                                    children = {
                                        {
                                            tab = {
                                                type = "tab",
                                                caption = { "gui-name.automated-train-depot-group-view" },
                                                ref = { "atd-concrete-group-view-tab" },
                                                actions = {
                                                    --on_click = { gui = "main", action = "change_tab", tab = "trains" },
                                                },
                                            },
                                            content = {
                                                type = "frame",
                                                --style = "ltnm_main_content_frame",
                                                direction = "vertical",
                                                ref = {"atd-concrete-group-view-content"},

                                            }
                                        }
                                    },
                                }
                            },
                        }
                    }
                }
            }
        }
    })

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    player.opened = refs.window

    global.gui[NAME][player.index] = {
        refs = refs,
        state = {
            entity = entity,
            previous_stats = "none",
        },
    }
end

function frame.destroy(player)
    local gui_data = global.gui[NAME][player.index]

    if gui_data then
        global.gui[NAME][player.index] = nil
        gui_data.refs.window.destroy()
    end
end

---@param action table
---@param event EventData
function frame.handle_action(action, event)
    if action.action == "close" then
        frame.close(event)
    end
end

function frame.close(event)
    local player = game.get_player(event.player_index)

    frame.destroy(player)
end

return frame