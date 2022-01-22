local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local constants = require("scripts.gui.frame.add_group.component.train_builder.constants")
local build_structure = require("scripts.gui.frame.add_group.component.train_builder.build_structure")
local validator = require("scripts.gui.validator")

local COMPONENT = constants.COMPONENT
local ACTION = constants.ACTION
local TRAIN_PART_TYPE = {
    LOCOMOTIVE = "locomotive",
    CARGO = "cargo",
}

local persistence = {
    init = function()
        global.gui_component[COMPONENT.NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui_component[COMPONENT.NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_all_train_parts = function(player)
        return global.gui_component[COMPONENT.NAME][player.index].train_parts
    end,
    ---@param player LuaPlayer
    ---@param container LuaGuiElement
    set_container = function(player, container)
        if global.gui_component[COMPONENT.NAME][player.index] == nil then
            global.gui_component[COMPONENT.NAME][player.index] = {
                container = container,
                train_parts = {},
            }
        end
    end,
    ---@param player LuaPlayer
    ---@return LuaGuiElement
    get_container = function(player)
        return global.gui_component[COMPONENT.NAME][player.index].container
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    ---@param refs table
    add_train_part = function(player, train_part_id, refs)
        table.insert(
            global.gui_component[COMPONENT.NAME][player.index].train_parts,
                train_part_id,
            { refs = refs }
        )
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    delete_train_part = function(player, train_part_id)
        flib_table.retrieve(global.gui_component[COMPONENT.NAME][player.index].train_parts, train_part_id)
    end,
    ---@param player LuaPlayer
    ---@param train_part_id int
    ---@return table
    get_train_part = function(player, train_part_id)
        return global.gui_component[COMPONENT.NAME][player.index].train_parts[train_part_id]
    end,
}

local on_form_changed_callback = function() end

local component = {}

local function validator_rule_has_locomotive(data)
    for _, train_part in pairs(data.v) do
        if train_part.type == TRAIN_PART_TYPE.LOCOMOTIVE then
            return nil
        end
    end

    return {"validation-message.locomotive-required"}
end

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
    ---@type int
    local train_part_id = get_train_part_id(event.element)
    local train_part = persistence.get_train_part(player, train_part_id)

    train_part.refs.element.destroy()
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
    local train_part_id = script.generate_event_name()
    local refs = flib_gui.build(container_element, {build_structure.get(train_part_id)})

    persistence.set_container(player, container_element)

    persistence.add_train_part(player, train_part_id, refs)
end

---@param callback function
function component.on_form_changed(callback)
    on_form_changed_callback = callback
end

---@return string
function component.name()
    return COMPONENT.NAME
end

---@param action table
---@param event EventData
function component.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = COMPONENT.NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) return add_new_train_part(e) end},
        { gui = COMPONENT.NAME, action = ACTION.TRAIN_CHANGED, func = function(_, e) return update_train_part(e) end},
        { gui = COMPONENT.NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION, func = function(_, e) return change_locomotive_direction(e) end},
        { gui = COMPONENT.NAME, action = ACTION.DELETE_TRAIN_PART, func = function(_, e) return delete_train_part(e) end},
    }

    for _, h in ipairs(event_handlers) do
        if h.gui == action.gui and (h.action == action.action or h.action == nil) then
            mod.util.logger.debug("Event handler for `{1}:{2}` executed", { h.gui, h.action});
            if h.func(action, event) then
                processed = true
            end
        end
    end

    if processed then
        on_form_changed_callback(event)
    end

    return processed
end

---@param event EventData
function component.read_form(event)
    local player = game.get_player(event.player_index)
    local train_parts = persistence.get_all_train_parts(player)

    local train = {}

    for i, el in pairs(train_parts) do
        local train_part = {}
        local part_chooser = el.refs.part_chooser
        local part_entity_type = part_chooser.elem_value

        if part_entity_type ~= nil then
            if is_locomotive_selected(part_entity_type) then
                train_part = {
                    type = TRAIN_PART_TYPE.LOCOMOTIVE,
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
                train_part = {
                    type = TRAIN_PART_TYPE.CARGO,
                    entity = part_entity_type
                }
            end

            table.insert(train, i, train_part)
        end
    end

    return train
end

---@param event EventData
function component.validate_form(event)
    local form_data = component.read_form(event)
    local validator_rules = {
        {
            match = validator.match_by_name("train"),
            rules = { validator_rule_has_locomotive },
        },
    }

    return validator.validate(validator_rules, {train = form_data})
end

return component