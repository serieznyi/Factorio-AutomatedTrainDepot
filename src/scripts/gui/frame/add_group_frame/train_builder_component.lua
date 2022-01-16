local flib_gui = require("__flib__.gui")

local validator = require("scripts.gui.validator")

local COMPONENT_NAME = "train_builder"

local LOCOMOTIVE_DIRECTION = {
    LEFT = 1,
    RIGHT = 2,
}

local ACTION = {
    TRAIN_CHANGED = "train_changed",
    DELETE_TRAIN_PART = "delete_train_part",
    CHANGE_LOCOMOTIVE_DIRECTION = "change_locomotive_direction",
    FORM_CHANGED = "form_changed",
}

---@type table
local persistence = {
    init = function()
        global.component[COMPONENT_NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.component[COMPONENT_NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_elements = function(player)
        return global.component[COMPONENT_NAME][player.index].elements
    end,
    ---@param player LuaPlayer
    ---@param parent_element LuaGuiElement
    set_parent = function(player, parent_element)
        if global.component[COMPONENT_NAME][player.index] == nil then
            global.component[COMPONENT_NAME][player.index] = {
                parent = parent_element,
                elements = {},
            }
        end
    end,
    ---@param player LuaPlayer
    ---@return LuaGuiElement
    get_parent = function(player)
        return global.component[COMPONENT_NAME][player.index].parent
    end,
    ---@param player LuaPlayer
    ---@param component_id int
    ---@param refs table
    add_element = function(player, component_id, refs)
        table.insert(
            global.component[COMPONENT_NAME][player.index].elements,
                component_id,
            { refs = refs }
        )
    end,
    ---@param player LuaPlayer
    ---@param element_id int
    ---@return table
    get_element = function(player, element_id)
        return global.component[COMPONENT_NAME][player.index].elements[element_id]
    end,
}

local component = {}

---@param element LuaGuiElement
---@param player LuaPlayer
local function get_locomotive_direction(element, player)
    local element_id = flib_gui.get_tags(element).element_id
    ---@type table
    local gui = persistence.get_element(player, element_id)
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
                    on_elem_changed = { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED },
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
                    on_click = { gui = COMPONENT_NAME, action = ACTION.DELETE_TRAIN_PART }
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
                type = "sprite-button",
                visible = false,
                tags = { element_id = element_id, direction = LOCOMOTIVE_DIRECTION.LEFT },
                ref = {"locomotive_direction_left_button"},
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_left",
                actions = {
                    on_click = { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
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
                    on_click = { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                }
            }
        }
    }
end

---@param player_index int
---@return bool
local function is_last_train_part_chooser_empty(player_index)
    local player = game.get_player(player_index)
    ---@type LuaGuiElement
    local container = persistence.get_parent(player)
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

---@param event EventData
local function change_locomotive_direction(event)
    local player = game.get_player(event.player_index)
    ---@type int
    local element_id = flib_gui.get_tags(event.element).element_id
    ---@type table
    local gui = persistence.get_element(player, element_id)
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

---@param value string|nil
---@return bool
local function is_locomotive_selected(value)
    if value == nil then
        return false
    end

    local prototype = game.entity_prototypes[value]

    return prototype.type == "locomotive"
end

---@param item_chooser LuaGuiElement
---@return bool
local function is_chooser_item_cleaned(item_chooser)
    return item_chooser.elem_value == nil and not is_last_train_part_chooser(item_chooser)
end

---@param event EventData
local function update_train_part_chooser(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type int
    local element_id = flib_gui.get_tags(event.element).element_id
    ---@type table
    local gui = persistence.get_element(player, element_id)
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent
    ---@type LuaGuiElement
    local delete_button = gui.refs.delete_button
    ---@type LuaGuiElement
    local locomotive_config_button = gui.refs.locomotive_config_button
    ---@type LuaGuiElement
    local locomotive_direction_left_button = gui.refs.locomotive_direction_left_button
    ---@type LuaGuiElement
    local locomotive_direction_right_button = gui.refs.locomotive_direction_right_button

    if is_chooser_item_cleaned(item_chooser) then
        chooser_wrapper.destroy()
        return
    end

    if item_chooser.elem_value == nil then
        return
    end

    -- init buttons
    locomotive_direction_left_button.visible = false
    locomotive_direction_right_button.visible = false
    locomotive_config_button.visible = false
    delete_button.visible = true

    if is_locomotive_selected(item_chooser.elem_value) then
        locomotive_config_button.visible = true
        locomotive_direction_left_button.visible = true
    end
end

---@param event EventData
local function delete_train_part_chooser(event)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent

    chooser_wrapper.destroy()
end

---@param event EventData
local function add_new_train_part_chooser(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local container = persistence.get_parent(player)


    if item_chooser.elem_value ~= nil and not is_last_train_part_chooser_empty(event.player_index) then
        component.append_component(container, player)
    end
end

function component.init()
    persistence.init()
end

---@param player LuaPlayer
function component.destroy(player)
    persistence.destroy(player)
end

---@param parent_element LuaGuiElement
---@param player LuaPlayer
function component.append_component(parent_element, player)
    local parent_children_count = #parent_element.children
    local refs = flib_gui.build(parent_element, {
        gui_build_structure_element(parent_children_count+1)
    })
    local tags = flib_gui.get_tags(refs.element)
    local element_id = tags.element_id

    persistence.set_parent(player, parent_element)

    persistence.add_element(player, element_id, refs)
end

---@return string
function component.name()
    return COMPONENT_NAME
end

---@param action table
---@param event EventData
function component.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) add_new_train_part_chooser(e) end},
        { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) update_train_part_chooser(e) end},
        { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION, func = function(_, e) change_locomotive_direction(e) end},
        { gui = COMPONENT_NAME, action = ACTION.DELETE_TRAIN_PART, func = function(_, e) delete_train_part_chooser(e) end},
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
function component.read_form(event)
    local player = game.get_player(event.player_index)
    local elements = persistence.get_elements(player)

    local train = {}

    for i, el in ipairs(elements) do
        local part = {}
        local part_chooser = el.refs.part_chooser
        local part_entity = part_chooser.elem_value

        if part_entity ~= nil then
            if is_locomotive_selected(part_entity) then
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
function component.validate_form(event)
    local form_data = component.read_form(event)
    local rules = {
        name = {
            function(value) return validator.empty(value) end,
        },
        icon = {
            function(value) return validator.empty(value) end,
        }
    }

    local validation_errors = {}

    for form_field_name, form_value in pairs(form_data) do
        for field_name, field_validators in pairs(rules) do
            if form_field_name == field_name then
                for _, field_validator in pairs(field_validators) do
                    local error = field_validator({k = form_field_name, v = form_value})

                    if error ~= nil then
                        table.insert(validation_errors, error)
                    end
                end
            end
        end
    end

    return validation_errors
end

return component