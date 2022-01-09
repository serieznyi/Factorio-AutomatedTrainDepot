local flib_gui = require("__flib__.gui")

local frame = {}

local FRAME_NAME = "main_frame"

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
                        type = "button",
                        caption = "add",
                        actions = {
                            on_click = { gui = "add_group_frame", action = "open" },
                        },
                    },
                    {
                        type = "flow",
                        name = "groups_container",
                        style_mods = {
                            maximal_width = 400, -- todo use var
                        },
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
                        type = "flow",
                        name = "group_view",
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
end

function frame.get_name()
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
        { action = ACTION.CLOSE, func = function() frame.close(event) end},
    }

    for _, handler in pairs(handlers) do
        if handler.action == action.action then
            handler.func()
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