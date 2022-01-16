local flib_gui = require("__flib__.gui")

local FRAME_NAME = "main_frame"
local FRAME_WIDTH = 1200;
local FRAME_HEIGHT = 600;

local ACTION = {
    CLOSE = "close",
}

local persistence = {
    init = function()
        global.gui[FRAME_NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui[FRAME_NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_gui = function(player)
        return global.gui[FRAME_NAME][player.index]
    end,
    ---@param player LuaPlayer
    ---@param refs table
    ---@param entity LuaEntity
    save_gui = function(player, refs)
        global.gui[FRAME_NAME][player.index] = {
            refs = refs,
        }
    end,
}

local frame = {}

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

---@param player LuaPlayer
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    local resolution, scale = player.display_resolution, player.display_scale
    refs.window.location = {
        ((resolution.width - (FRAME_WIDTH * scale)) / 2),
        ((resolution.height - (FRAME_HEIGHT * scale)) / 2)
    }

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
end

---@param player LuaPlayer
local function update_for(player)
    local gui = persistence.get_gui(player)

    -- TODO

    return gui
end

---@return table
function frame.remote_interfaces()
    return {

    }
end

---@return string
function frame.name()
    return FRAME_NAME
end

function frame.init()
    persistence.init()
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.open(player)
    local gui = persistence.get_gui(player)

    if gui == nil then
        gui = create_for(player)
    else
        gui = update_for(player)
    end

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    player.opened = gui.refs.window
end

function frame.destroy(player)
    local gui_data = persistence.get_gui(player)

    if gui_data == nil then
        return
    end

    gui_data.refs.window.visible = false
    gui_data.refs.window.destroy()

    persistence.destroy(player)
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME_NAME, action = ACTION.CLOSE, func = function(_, e) frame.close(e) end},
    }

    for _, h in ipairs(event_handlers) do
        if h.gui == action.gui and (h.action == action.action or h.action == nil) then
            if h.func(action, event) then
                processed = true
            end
        end
    end

    return processed
end

function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    gui.refs.window.visible = false

    if player.opened == gui.refs.window then
        player.opened = nil
    end
end

return frame