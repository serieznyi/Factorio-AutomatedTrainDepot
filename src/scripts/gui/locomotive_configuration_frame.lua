local flib_gui = require("__flib__.gui")

local FRAME_NAME = "locomotive_configuration_frame"

local ACTION = {
    OPEN = "open",
    CLOSE = "close",
}

local frame = {}

---@return table
local function gui_build_structure_frame()
    return {
        type = "frame",
        name = FRAME_NAME,
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
                        caption = {"gui-name.automated-train-depot-configure-locomotive"},
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
                style = "inner_frame_in_outer_frame",
                direction = "vertical",
                children = {
                    {
                        type = "flow",
                        direction = "vertical",
                        children = {
                            {
                                type = "label",
                                caption = "Group name",
                            },
                            {
                                type = "textfield",
                            }
                        }
                    },
                    {
                        type = "flow",
                        direction = "vertical",
                        children = {
                            {
                                type = "label",
                                caption = "Build train",
                            },
                            {
                                type = "frame",
                                direction = "horizontal",
                                ref  =  {"train_building_container"},
                                children = {
                                    gui_build_structure_train_part_chooser(),
                                }
                            }
                        }
                    },
                    -- Control buttons
                    {
                        type = "flow",
                        style = "flib_titlebar_flow",
                        children = {
                            {
                                type = "button",
                                caption = "Cancel",
                                actions = {
                                    on_click = { gui = "add_group_frame", action = "close" },
                                },
                            },
                            {
                                type = "empty-widget",
                                style = "flib_titlebar_drag_handle",
                                ignored_by_interaction = true
                            },
                            {
                                type = "button",
                                caption = "Create",
                            },
                        }
                    }
                }
            }
        }
    }
end

---@param player LuaPlayer
local function create(player)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    global.gui[FRAME_NAME][player.index] = {
        refs = refs,
        state = {
            visible = false,
        },
    }
end

---@param player LuaPlayer
---@param entity LuaEntity
local function update(player, entity)
    -- TODO
end

---@return string
function frame.name()
    return FRAME_NAME
end

function frame.init()
    global.gui[FRAME_NAME] = {}
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.open(player, entity)
    if global.gui[FRAME_NAME][player.index] == nil then
        create(player, entity)
    else
        update(player, entity)
    end

    local gui = global.gui[FRAME_NAME][player.index]

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    gui.state.visible = true
    player.opened = gui.refs.window
end

---@param player LuaPlayer
---@param event EventData
function frame.destroy(player, event)
    local gui_data = global.gui[FRAME_NAME][player.index]

    if gui_data then
        global.gui[FRAME_NAME][player.index] = nil
        gui_data.refs.window.destroy()
    end
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local player = game.get_player(event.player_index)

    local handlers = {
        { action = ACTION.CLOSE, func = function() frame.destroy(player, event) end},
        { action = ACTION.OPEN, func = function() frame.open(player, event) end},
        { action = ACTION.TRAIN_CHANGED, func = function() add_new_train_part_chooser(action, event) end},
        { action = ACTION.TRAIN_CHANGED, func = function() update_train_part_chooser(action, event) end},
        { action = ACTION.DELETE_TRAIN_PART_CHOOSER, func = function() delete_train_part_chooser(action, event) end},
    }

    for _, handler in pairs(handlers) do
        if handler.action == action.action then
            handler.func()
        end
    end
end

return frame