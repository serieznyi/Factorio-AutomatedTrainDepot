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
    FORM_CHANGED = automated_train_depot.constants.gui.common_actions.form_changed,
}

local VALIDATION_RULES = {
    trains = {
        function(value) return validator.empty(value) end,
    },
}

local persistence = {
    init = function()
        global.gui_component[COMPONENT_NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui_component[COMPONENT_NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_all_train_parts = function(player)
        return global.gui_component[COMPONENT_NAME][player.index].train_parts
    end,
    ---@param player LuaPlayer
    ---@param container LuaGuiElement
    set_container = function(player, container)
        if global.gui_component[COMPONENT_NAME][player.index] == nil then
            global.gui_component[COMPONENT_NAME][player.index] = {
                container = container,
                train_parts = {},
            }
        end
    end,
    ---@param player LuaPlayer
    ---@return LuaGuiElement
    get_container = function(player)
        return global.gui_component[COMPONENT_NAME][player.index].container
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    ---@param refs table
    add_train_part = function(player, train_part_id, refs)
        table.insert(
            global.gui_component[COMPONENT_NAME][player.index].train_parts,
                train_part_id,
            { refs = refs }
        )
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    delete_train_part = function(player, train_part_id)
        table.remove(global.gui_component[COMPONENT_NAME][player.index].train_parts, train_part_id)
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    ---@return table
    get_train_part = function(player, train_part_id)
        return global.gui_component[COMPONENT_NAME][player.index].train_parts[train_part_id]
    end,
}

local on_form_changed_callback = function() end

local component = {}

---@param element LuaGuiElement
---@return int
local function get_train_part_id(element)
    local tags = flib_gui.get_tags(element)

    return tags.train_part_id
end

---@param element LuaGuiElement
---@param player LuaPlayer
local function get_locomotive_direction(element, player)
    local train_part_id = get_train_part_id(element)
    ---@type table
    local train_part = persistence.get_train_part(player, train_part_id)
    local left_button = train_part.refs.locomotive_direction_left_button
    local right_button = train_part.refs.locomotive_direction_right_button

    local direction_button

    if left_button.visible then
        direction_button = left_button
    else
        direction_button = right_button
    end

    return flib_gui.get_tags(direction_button).direction
end

---@param train_part_id int
---@return table
local function gui_build_structure_element(train_part_id)
    return {
        type = "flow",
        direction = "vertical",
        ref = { "element" },
        tags = {train_part_id = train_part_id },
        children = {
            {
                type = "choose-elem-button",
                tags = {train_part_id = train_part_id },
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
                tags = {train_part_id = train_part_id },
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
                tags = {train_part_id = train_part_id },
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
                on_click = { gui = "locomotive_configuration_frame", action = "open" },
            },
            {
                type = "sprite-button",
                visible = false,
                tags = { train_part_id = train_part_id, direction = LOCOMOTIVE_DIRECTION.LEFT },
                ref = {"locomotive_direction_left_button"},
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_left",
                actions = {
                    on_click = { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                }
            },
            {
                type = "sprite-button",
                tags = { train_part_id = train_part_id, direction = LOCOMOTIVE_DIRECTION.RIGHT },
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
local function is_last_train_part_empty(player_index)
    local player = game.get_player(player_index)
    ---@type LuaGuiElement
    local container = persistence.get_container(player)
    ---@type LuaGuiElement
    local last_train_part = container.children[#container.children]

    -- TODO
    return last_train_part.children[1].elem_value == nil
end

---@param choose_elem_button_element LuaGuiElement
---@return LuaGuiElement
local function is_last_train_part_selector(choose_elem_button_element)
    -- TODO refactor
    local chooser_wrapper = choose_elem_button_element.parent
    local choosers_container = choose_elem_button_element.parent.parent

    return chooser_wrapper.get_index_in_parent() == #choosers_container.children
end

---@param event EventData
local function change_locomotive_direction(event)
    local player = game.get_player(event.player_index)
    ---@type int
    local train_part_id = flib_gui.get_tags(event.element).train_part_id
    ---@type table
    local train_part = persistence.get_train_part(player, train_part_id)
    ---@type LuaGuiElement
    local locomotive_direction_left_button = train_part.refs.locomotive_direction_left_button
    ---@type LuaGuiElement
    local locomotive_direction_right_button = train_part.refs.locomotive_direction_right_button

    if locomotive_direction_left_button.visible then
        locomotive_direction_left_button.visible = false
        locomotive_direction_right_button.visible = true
    else
        locomotive_direction_left_button.visible = true
        locomotive_direction_right_button.visible = false
    end

    return true
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

---@param item_selector LuaGuiElement
---@return bool
local function is_train_part_selector_cleaned(item_selector)
    return item_selector.elem_value == nil and not is_last_train_part_selector(item_selector)
end

---@param event EventData
local function update_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    local train_part_id = get_train_part_id(item_chooser)
    ---@type table
    local train_part = persistence.get_train_part(player, train_part_id)
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent
    ---@type LuaGuiElement
    local delete_button = train_part.refs.delete_button
    ---@type LuaGuiElement
    local locomotive_config_button = train_part.refs.locomotive_config_button
    ---@type LuaGuiElement
    local locomotive_direction_left_button = train_part.refs.locomotive_direction_left_button
    ---@type LuaGuiElement
    local locomotive_direction_right_button = train_part.refs.locomotive_direction_right_button

    if is_train_part_selector_cleaned(item_chooser) then
        chooser_wrapper.destroy()
        persistence.delete_train_part(player, train_part_id)
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

    return true
end

---@param event EventData
local function delete_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local chooser_wrapper = item_chooser.parent

    chooser_wrapper.destroy()
    persistence.delete_train_part(player, train_part_id)

    return true
end

---@param event EventData
local function add_new_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local container = persistence.get_container(player)

    if item_chooser.elem_value ~= nil and not is_last_train_part_empty(event.player_index) then
        component.append_component(container, player)
    end

    return true
end

function component.init()
    persistence.init()
end

---@param player LuaPlayer
function component.destroy(player)
    persistence.destroy(player)
end

---@param container_element LuaGuiElement
---@param player LuaPlayer
function component.append_component(container_element, player)
    local train_part_id = math.random(1, 1000000)
    local refs = flib_gui.build(container_element, {
        gui_build_structure_element(train_part_id)
    })

    persistence.set_container(player, container_element)

    persistence.add_train_part(player, train_part_id, refs)
end

---@param callback function
function component.on_form_changed(callback)
    on_form_changed_callback = callback
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
        { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) return add_new_train_part(e) end},
        { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) return update_train_part(e) end},
        { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION, func = function(_, e) return change_locomotive_direction(e) end},
        { gui = COMPONENT_NAME, action = ACTION.DELETE_TRAIN_PART, func = function(_, e) return delete_train_part(e) end},
    }

    for _, h in ipairs(event_handlers) do
        if h.gui == action.gui and (h.action == action.action or h.action == nil) then
            if h.func(action, event) then
                on_form_changed_callback(event)
                processed = true
            end
        end
    end

    return processed
end

---@param event EventData
function component.read_form(event)
    local player = game.get_player(event.player_index)
    local elements = persistence.get_all_train_parts(player)

    local train = {}

    for i, el in pairs(elements) do
        local part = {}
        local part_chooser = el.refs.part_chooser
        local part_entity_type = part_chooser.elem_value

        if part_entity_type ~= nil then
            if is_locomotive_selected(part_entity_type) then
                part = {
                    type = "locomotive",
                    entity = part_entity_type,
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
                    entity = part_entity_type
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

    return validator.validate(VALIDATION_RULES, form_data)
end

return component