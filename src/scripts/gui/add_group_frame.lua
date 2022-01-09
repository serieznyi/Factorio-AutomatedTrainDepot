local flib_gui = require("__flib__.gui")

local NAME = "add_group_frame"

local frame = {}

---@param container LuaGuiElement
---@return bool
local function is_last_stock_chooser_empty(container)
    local chooser_container = container.children[#container.children]

    return chooser_container.children[1].elem_value == nil
end

---@param choose_elem_button_element LuaGuiElement
---@return LuaGuiElement
local function is_last_stock_chooser(choose_elem_button_element)
    local chooser_wrapper = choose_elem_button_element.parent
    local choosers_container = choose_elem_button_element.parent.parent

    return chooser_wrapper.get_index_in_parent() == #choosers_container.children
end

---@return table
local function gui_build_structure_rolling_stock_item_chooser()
    return {
        type = "flow",
        direction = "vertical",
        tags = {type = "chooser_wrapper"},
        children = {
            {
                type = "choose-elem-button",
                name = "item_chooser",
                elem_type = "entity",
                elem_filters = {
                    {filter="rolling-stock"},
                },
                actions = {
                    on_elem_changed = { gui = "add_group_frame", action = "stock_changed" },
                }
            },
            {
                type = "sprite-button",
                name = "delete_button",
                visible = false,
                style = "flib_slot_button_red",
                sprite = "atd_sprite_trash",
            },
            {
                type = "sprite-button",
                name = "locomotive_configuration_button",
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
            },
        }
    }
end

---@param action table
---@param event EventData
local function update_stock_chooser(action, event)
    ---@type LuaGuiElement
    local element = event.element
    ---@type LuaGuiElement
    local chooser_container = element.parent

    if element.elem_value == nil and not is_last_stock_chooser(element) then
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
local function append_new_stock_chooser(action, event)
    ---@type LuaGuiElement
    local element = event.element
    ---@type LuaGuiElement
    local container = element.parent.parent

    if element.elem_value ~= nil and not is_last_stock_chooser_empty(container) then
        flib_gui.add(container, gui_build_structure_rolling_stock_item_chooser())
    end
end

---@param player LuaPlayer
local function create(player)
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
                                    ref  =  {"rolling_stock_container"},
                                    children = {
                                        gui_build_structure_rolling_stock_item_chooser(),
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
    })

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    global.gui[NAME][player.index] = {
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
    return NAME
end

function frame.init()
    global.gui[NAME] = {}
end

---@param player LuaPlayer
---@param entity LuaEntity
function frame.open(player, entity)
    if global.gui[NAME][player.index] == nil then
        create(player, entity)
    else
        update(player, entity)
    end

    local gui = global.gui[NAME][player.index]

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    gui.state.visible = true
    player.opened = gui.refs.window
end

---@param player LuaPlayer
---@param event EventData
function frame.destroy(player, event)
    local gui_data = global.gui[NAME][player.index]

    if gui_data then
        global.gui[NAME][player.index] = nil
        gui_data.refs.window.destroy()
    end
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local player = game.get_player(event.player_index)

    if action.action == "close" then
        frame.destroy(player, event)
    elseif action.action == "open" then
        frame.open(player, event)
    elseif action.action == "stock_changed" then
        append_new_stock_chooser(action, event)
        update_stock_chooser(action, event)
    end
end

return frame