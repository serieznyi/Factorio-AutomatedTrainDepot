local flib_gui = require("__flib__.gui")

local NAME = "add_group_frame"

local frame = {}

function frame.get_name()
    return NAME
end

function frame.init()
    global.gui[NAME] = {}
end

---@param player LuaPlayer
function frame.create(player)
    local refs = flib_gui.build(player.gui.screen, {
        {
            type = "frame",
            name = "add_group_frame",
            direction = "vertical",
            ref  =  {"window"},
            style_mods = {
                natural_width = 400,
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
                            caption = {"gui-name.automated-train-depot-add-group-frame"},
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
                    direction = "horizontal",
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
function frame.dispatch(action, event)
    if action.action == "close" then
        frame.close(event)
    elseif action.action == "create" then
        frame.create(game.get_player(event.player_index))
    end
end

function frame.close(event)
    local player = game.get_player(event.player_index)

    frame.destroy(player)
end

return frame