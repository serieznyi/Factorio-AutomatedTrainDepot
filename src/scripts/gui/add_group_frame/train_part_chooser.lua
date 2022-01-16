local flib_gui = require("__flib__.gui")

local ELEMENT_NAME = "train_part_chooser"

local LOCOMOTIVE_DIRECTION = {
    LEFT = 1,
    RIGHT = 2,
}

local ACTION = {
    TRAIN_CHANGED = "train_changed",
    DELETE_TRAIN_PART_CHOOSER = "delete_train_part_chooser",
    CHANGE_LOCOMOTIVE_DIRECTION = "change_locomotive_direction",
    FORM_CHANGED = "form_changed",
}

local element = {}

---@param element_arg LuaGuiElement
---@param player LuaPlayer
local function get_locomotive_direction(element_arg, player)
    local element_id = flib_gui.get_tags(element_arg).element_id
    ---@type table
    local gui = global.element[ELEMENT_NAME][player.index].elements[element_id]
    local left_button = gui.refs.locomotive_direction_left_button
    local right_button = gui.refs.locomotive_direction_right_button

    local direction_button

    if left_button.visible then
        direction_button = left_button
    else
        direction_button = right_button
    end

    return flib_gui.get_tags(direction_button).direction
end

---@param element_id int
---@return table
local function gui_build_structure_element(element_id)
    return {
        type = "flow",
        direction = "vertical",
        ref = { "element" },
        tags = {element_id = element_id},
        children = {
            {
                type = "choose-elem-button",
                tags = {element_id = element_id},
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
                tags = {element_id = element_id},
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
                tags = {element_id = element_id},
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
                        visible = false,
                        tags = { element_id = element_id, direction = LOCOMOTIVE_DIRECTION.LEFT },
                        ref = {"locomotive_direction_left_button"},
                        style = "flib_slot_button_default",
                        sprite = "atd_sprite_arrow_left",
                        actions = {
                            on_click = { gui = ELEMENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                        }
                    },
                    {
                        type = "sprite-button",
                        tags = { element_id = element_id, direction = LOCOMOTIVE_DIRECTION.RIGHT },
                        ref = {"locomotive_direction_right_button"},
                        visible = false,
                        style = "flib_slot_button_default",
                        sprite = "atd_sprite_arrow_right",
                        actions = {
                            on_click = { gui = ELEMENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                        }
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
    ---@type int
    local element_id = flib_gui.get_tags(event.element).element_id
    ---@type table
    local gui = global.element[ELEMENT_NAME][event.player_index].elements[element_id]
    ---@type LuaGuiElement
    local locomotive_direction_left_button = gui.refs.locomotive_direction_left_button
    ---@type LuaGuiElement
    local locomotive_direction_right_button = gui.refs.locomotive_direction_right_button

    if locomotive_direction_left_button.visible then
        locomotive_direction_left_button.visible = false
        locomotive_direction_right_button.visible = true
    else
        locomotive_direction_left_button.visible = true
        locomotive_direction_right_button.visible = false
    end
end

---@param item_chooser LuaGuiElement
---@return bool
local function is_locomotive_chosen(value)
    local prototype = game.entity_prototypes[value]

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
    local element_id = flib_gui.get_tags(event.element).element_id
    ---@type table
    local gui = global.element[ELEMENT_NAME][event.player_index].elements[element_id]
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent
    ---@type LuaGuiElement
    local delete_button = gui.refs.delete_button
    ---@type LuaGuiElement
    local locomotive_config_button = gui.refs.locomotive_config_button
    ---@type LuaGuiElement
    local locomotive_direction_left_button = gui.refs.locomotive_direction_left_button

    if is_chooser_item_cleaned(item_chooser) then
        chooser_wrapper.destroy()
        return
    end

    -- init buttons
    locomotive_direction_left_button.visible = false
    locomotive_config_button.visible = false
    delete_button.visible = true

    if is_locomotive_chosen(item_chooser.elem_value) then
        locomotive_config_button.visible = true
        locomotive_direction_left_button.visible = true
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
    local parent_children_count = #parent_element.children
    local refs = flib_gui.build(parent_element, {
        gui_build_structure_element(parent_children_count+1)
    })
    local tags = flib_gui.get_tags(refs.element)
    local element_id = tags.element_id

    if global.element[ELEMENT_NAME][player.index] == nil then
        global.element[ELEMENT_NAME][player.index] = {
            parent = parent_element,
            elements = {},
        }
    end

    table.insert(
        global.element[ELEMENT_NAME][player.index].elements,
        element_id,
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
    local processed = false

    local event_handlers = {
        { gui = ELEMENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(a, e) add_new_train_part_chooser(a, e) end},
        { gui = ELEMENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(a, e) update_train_part_chooser(a, e) end},
        { gui = ELEMENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION, func = function(a, e) change_locomotive_direction(a, e) end},
        { gui = ELEMENT_NAME, action = ACTION.DELETE_TRAIN_PART_CHOOSER, func = function(a, e) delete_train_part_chooser(a, e) end},
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

---@param event EventData
function element.read_form(event)
    local player = game.get_player(event.player_index)
    local elements = global.element[ELEMENT_NAME][player.index].elements

    local train = {}

    for i, el in ipairs(elements) do
        local part = {}
        local part_chooser = el.refs.part_chooser
        local part_entity = part_chooser.elem_value

        if part_entity ~= nil then
            if is_locomotive_chosen(part_entity) then
                part = {
                    type = "locomotive",
                    entity = part_entity,
                    direction = get_locomotive_direction(part_chooser, player),
                    use_any_fuel = true,
                    fuel = {
                        {type = "coal", amount = 1},
                        {type = "coal", amount = 1},
                        {type = "coal", amount = 1},
                    },
                    inventory = {
                        {entity = "entity1"},
                        {entity = "entity2"},
                        {entity = "entity3"},
                    },
                }
            else
                part = {
                    type = "cargo",
                    entity = part_entity
                }
            end

            table.insert(train, i, part)
        end
    end

    return train
end

---@param event EventData
function element.validate_form(event)
    local form_data = element.read_form(event)

    local validation_errors = {}


    return validation_errors
end

return element