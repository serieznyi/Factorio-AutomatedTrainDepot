local flib_gui = require("__flib__.gui")

local frame = {}

local FRAME_NAME = "main_frame"
local FRAME_WIDTH = 1200;
local FRAME_HEIGHT = 600;

local ACTION = {
    CLOSE = "close",
}

---@return table
local function gui_build_structure_frame()
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
                            on_click = {gui = FRAME_NAME, action = ACTION.CLOSE}
                        }
                    }
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
                                                tooltip = {"gui.add_new_group"},
                                                sprite = "atd_sprite_add",
                                                actions = {
                                                    on_click = { gui = "add_group_frame", action = "open" },
                                                },
                                            },
                                        }
                                    },
                                }
                            },
                            {
                                type = "flow",
                                direction = "vertical",
                                name = "groups_container",
                                children = {
                                    {
                                        type = "frame",
                                        style = "inside_deep_frame",
                                        children = {
                                            {
                                                type = "scroll-pane",
                                                style_mods = {
                                                    vertically_stretchable = true,
                                                    horizontally_stretchable = true,
                                                },
                                                style = "atd_scroll-pane_fake_listbox",
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

function frame.remote_interfaces()
    return {

    }
end

function frame.name()
    return FRAME_NAME
end

function frame.init()
    global.gui[FRAME_NAME] = {}
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.update(player, entity)
    -- TODO
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.open(player, entity)
    if global.gui[FRAME_NAME][player.index] == nil then
        frame.create(player, entity)
    else
        frame.update(player, entity)
    end

    local gui = global.gui[FRAME_NAME][player.index]

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    gui.state.visible = true
    player.opened = gui.refs.window
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.create(player, entity)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    local resolution, scale = player.display_resolution, player.display_scale
    refs.window.location = {
        ((resolution.width - (FRAME_WIDTH * scale)) / 2),
        ((resolution.height - (FRAME_HEIGHT * scale)) / 2)
    }

    global.gui[FRAME_NAME][player.index] = {
        refs = refs,
        state = {
            entity = entity,
            visible = false
        },
    }
end

function frame.destroy(player)
    local gui_data = global.gui[FRAME_NAME][player.index]

    if gui_data then
        global.gui[FRAME_NAME][player.index] = nil
        gui_data.refs.window.destroy()
    end
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local handlers = {
        { action = ACTION.CLOSE, func = function(_, e) frame.close(e) end},
    }

    for _, handler in pairs(handlers) do
        if handler.action == action.action then
            handler.func(action, event)
        end
    end
end

function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = global.gui[FRAME_NAME][player.index]

    gui.refs.window.visible = false
    gui.state.visible = false

    if player.opened == gui.refs.window then
        player.opened = nil
    end
end

return frame