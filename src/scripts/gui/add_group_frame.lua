local flib_gui = require("__flib__.gui")

local FRAME_NAME = "add_group_frame"

local ACTION = {
    TRAIN_CHANGED = "train_changed",
    OPEN = "open",
    CLOSE = "close",
    DELETE_TRAIN_PART_CHOOSER = "delete_train_part_chooser",
}

local frame = {}

---@return table
local function gui_build_structure_train_part_chooser()
    return {
        type = "flow",
        direction = "vertical",
        tags = {type = "train_part_chooser_wrapper"},
        children = {
            {
                type = "choose-elem-button",
                name = "part_chooser",
                elem_type = "entity",
                elem_filters = {
                    {filter="rolling-stock"},
                },
                actions = {
                    on_elem_changed = { gui = "add_group_frame", action = ACTION.TRAIN_CHANGED },
                }
            },
            {
                type = "sprite-button",
                name = "delete_button",
                visible = false,
                style = "flib_slot_button_red",
                sprite = "atd_sprite_trash",
                actions = {
                    on_click = {gui = FRAME_NAME, action = ACTION.DELETE_TRAIN_PART_CHOOSER}
                }
            },
            {
                type = "sprite-button",
                name = "locomotive_configuration_button",
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
            },
            {
                type = "sprite-button",
                name = "locomotive_direction_button",
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
            },
        }
    }
end

---@return table
local function gui_build_structure_frame()
    return {
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

---@param player_index int
---@return LuaGuiElement
local function get_train_building_container(player_index)
    return global.gui[FRAME_NAME][player_index].refs.train_building_container
end

---@param player_index int
---@return bool
local function is_last_train_part_chooser_empty(player_index)
    ---@type LuaGuiElement
    local container = get_train_building_container(player_index)

    local chooser_container = container.children[#container.children]

    return chooser_container.children[1].elem_value == nil
end

---@param choose_elem_button_element LuaGuiElement
---@return LuaGuiElement
local function is_last_train_part_chooser(choose_elem_button_element)
    local chooser_wrapper = choose_elem_button_element.parent
    local choosers_container = choose_elem_button_element.parent.parent

    return chooser_wrapper.get_index_in_parent() == #choosers_container.children
end

---@param action table
---@param event EventData
local function update_train_part_chooser(action, event)
    ---@type LuaGuiElement
    local element = event.element
    ---@type LuaGuiElement
    local chooser_container = element.parent

    if element.elem_value == nil and not is_last_train_part_chooser(element) then
        chooser_container.destroy()
        return
    end

    local prototype = game.entity_prototypes[element.elem_value]

    if prototype == nil then
        chooser_container.children[3].visible = false
    else
        chooser_container.children[2].visible = true

        if prototype.type == "locomotive" then
            chooser_container.children[3].visible = true
        end
    end
end

---@param action table
---@param event EventData
local function delete_train_part_chooser(action, event)
    ---@type LuaGuiElement
    local element = event.element

    element.parent.destroy()
end

---@param action table
---@param event EventData
local function add_new_train_part_chooser(action, event)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local container = get_train_building_container(event.player_index)

    if item_chooser.elem_value ~= nil and not is_last_train_part_chooser_empty(event.player_index) then
        flib_gui.add(container, gui_build_structure_train_part_chooser())
    end
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
function frame.get_name()
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