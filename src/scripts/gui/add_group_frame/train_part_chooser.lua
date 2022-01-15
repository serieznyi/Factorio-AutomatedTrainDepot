local flib_gui = require("__flib__.gui")

local develop = require("scripts.develop")

local ELEMENT_NAME = "train_part_chooser"

local LOCOMOTIVE_DIRECTION = {
    LEFT = 1,
    RIGHT = 2,
}

local ACTION = {
    TRAIN_CHANGED = "train_changed",
    DELETE_TRAIN_PART_CHOOSER = "delete_train_part_chooser",
    CHANGE_LOCOMOTIVE_DIRECTION = "change_locomotive_direction",
}

local element = {}

local function generate_id()
    return math.random(1, 100000000)
end

---@return table
local function gui_build_structure_element()
    local chooser_id = generate_id()

    return {
        type = "flow",
        direction = "vertical",
        ref = { "element" },
        tags = {chooser_id = chooser_id},
        children = {
            {
                type = "choose-elem-button",
                tags = {chooser_id = chooser_id},
                ref = { "part_chooser" },
                elem_type = "entity",
                elem_filters = {
                    {filter="rolling-stock"},
                },
                actions = {
                    on_elem_changed = { gui = ELEMENT_NAME, action = ACTION.TRAIN_CHANGED },
                }
            },
            {
                type = "sprite-button",
                ref = { "delete_button" },
                tags = {chooser_id = chooser_id},
                visible = false,
                style = "flib_slot_button_red",
                sprite = "atd_sprite_trash",
                actions = {
                    on_click = { gui = ELEMENT_NAME, action = ACTION.DELETE_TRAIN_PART_CHOOSER}
                }
            },
            {
                type = "sprite-button",
                ref = { "locomotive_config_button" },
                name = "locomotive_config_button",
                tags = {chooser_id = chooser_id},
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
                on_click = { gui = "locomotive_configuration_frame", action = "open" },
            },
            {
                type = "flow",
                children = {
                    {
                        type = "sprite-button",
                        name = "locomotive_direction_left_button",
                        visible = false,
                        tags = {direction = LOCOMOTIVE_DIRECTION.LEFT},
                        style = "flib_slot_button_default",
                        sprite = "atd_sprite_arrow_left",
                        on_click = { gui = ELEMENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                    },
                    {
                        type = "sprite-button",
                        name = "locomotive_direction_right_button",
                        tags = {direction = LOCOMOTIVE_DIRECTION.RIGHT},
                        visible = false,
                        style = "flib_slot_button_default",
                        sprite = "atd_sprite_arrow_left",
                        on_click = { gui = ELEMENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                    }
                }
            },
        }
    }
end

---@param player_index int
---@return bool
local function is_last_train_part_chooser_empty(player_index)
    ---@type LuaGuiElement
    local container = global.element[ELEMENT_NAME][player_index].parent
    ---@type LuaGuiElement
    local chooser_container = container.children[#container.children]

    -- TODO
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
local function change_locomotive_direction(action, event)
    ---@type LuaGuiElement
    local element = event.element

    automated_train_depot.console.debug(action.action)
end

---@param item_chooser LuaGuiElement
---@return bool
local function is_locomotive_chosen(item_chooser)
    local prototype = game.entity_prototypes[item_chooser.elem_value]

    return prototype.type == "locomotive"
end

---@param item_chooser LuaGuiElement
---@return bool
local function is_chooser_item_cleaned(item_chooser)
    return item_chooser.elem_value == nil and not is_last_train_part_chooser(item_chooser)
end

---@param action table
---@param event EventData
local function update_train_part_chooser(action, event)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type int
    local chooser_id = flib_gui.get_tags(event.element).chooser_id
    ---@type table
    local gui = global.element[ELEMENT_NAME][event.player_index].elements[chooser_id]
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent
    ---@type LuaGuiElement
    local delete_button = gui.refs.delete_button
    ---@type LuaGuiElement
    local locomotive_config_button = gui.refs.locomotive_config_button

    if is_chooser_item_cleaned(item_chooser) then
        chooser_wrapper.destroy()
        return
    end

    if is_locomotive_chosen(item_chooser) then
        locomotive_config_button.visible = true
        delete_button.visible = true
    else
        locomotive_config_button.visible = false
        delete_button.visible = true
    end
end

---@param action table
---@param event EventData
local function delete_train_part_chooser(action, event)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent

    chooser_wrapper.destroy()
end

---@param action table
---@param event EventData
local function add_new_train_part_chooser(action, event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local container = global.element[ELEMENT_NAME][event.player_index].parent

    if item_chooser.elem_value ~= nil and not is_last_train_part_chooser_empty(event.player_index) then
        element.append_element_to(container, player)
    end
end

function element.init()
    global.element[ELEMENT_NAME] = {}
end

---@param player LuaPlayer
function element.destroy(player)
    global.element[ELEMENT_NAME][player.index] = nil
end

---@param parent_element LuaGuiElement
---@param player LuaPlayer
function element.append_element_to(parent_element, player)
    local refs = flib_gui.build(parent_element, { gui_build_structure_element() })
    local tags = flib_gui.get_tags(refs.element)
    local chooser_id = tags.chooser_id

    if global.element[ELEMENT_NAME][player.index] == nil then
        global.element[ELEMENT_NAME][player.index] = {
            parent = parent_element,
            elements = {},
        }
    end

    table.insert(
        global.element[ELEMENT_NAME][player.index].elements,
        chooser_id,
        {refs = refs }
    )
end

---@return string
function element.name()
    return ELEMENT_NAME
end

---@param action table
---@param event EventData
function element.dispatch(action, event)
    local handlers = {
        { action = ACTION.TRAIN_CHANGED, func = function(a, e) add_new_train_part_chooser(a, e) end},
        { action = ACTION.TRAIN_CHANGED, func = function(a, e) update_train_part_chooser(a, e) end},
        { action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION, func = function(a, e) change_locomotive_direction(a, e) end},
        { action = ACTION.DELETE_TRAIN_PART_CHOOSER, func = function(a, e) delete_train_part_chooser(a, e) end},
    }

    for _, handler in pairs(handlers) do
        if handler.action == action.action then
            handler.func(action, event)
        end
    end
end

return element