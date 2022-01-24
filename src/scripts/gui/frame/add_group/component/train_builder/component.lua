local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")

local constants = require("scripts.gui.frame.add_group.component.train_builder.constants")
local build_structure = require("scripts.gui.frame.add_group.component.train_builder.build_structure")
local validator = require("scripts.gui.validator")

local COMPONENT = constants.COMPONENT
local TRAIN_PART_TYPE = {
    LOCOMOTIVE = "locomotive",
    CARGO = "cargo",
}

local public = {}
local private = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.init()
    global.gui.component[COMPONENT.NAME] = {}
end

---@param player LuaPlayer
function storage.destroy(player)
    global.gui.component[COMPONENT.NAME][player.index] = nil
end

---@param player LuaPlayer
---@return table
function storage.get_all_train_parts(player)
    return global.gui.component[COMPONENT.NAME][player.index].train_parts
end

---@param player LuaPlayer
---@param container LuaGuiElement
function storage.set_container(player, container)
    if global.gui.component[COMPONENT.NAME][player.index] == nil then
        global.gui.component[COMPONENT.NAME][player.index] = {
            container = container,
            train_parts = {},
        }
    end
end

---@param player LuaPlayer
---@return LuaGuiElement
function storage.get_container(player)
    return global.gui.component[COMPONENT.NAME][player.index].container
end

---@param player LuaPlayer
---@param train_part_id int
---@param refs table
function storage.add_train_part(player, train_part_id, refs)
    table.insert(
            global.gui.component[COMPONENT.NAME][player.index].train_parts,
            train_part_id,
            { refs = refs }
    )
end

---@param player LuaPlayer
---@param train_part_id int
function storage.delete_train_part(player, train_part_id)
    flib_table.retrieve(global.gui.component[COMPONENT.NAME][player.index].train_parts, train_part_id)
end

---@param player LuaPlayer
---@param train_part_id int
---@return table
function storage.get_train_part(player, train_part_id)
    return global.gui.component[COMPONENT.NAME][player.index].train_parts[train_part_id]
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param event EventData
function private.handle_update_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    local train_part_id = private.get_train_part_id(item_chooser)
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
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

    if private.is_train_part_selector_cleaned(item_chooser) then
        chooser_wrapper.destroy()
        storage.delete_train_part(player, train_part_id)
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

    if private.is_locomotive_selected(item_chooser.elem_value) then
        locomotive_config_button.visible = true
        locomotive_direction_left_button.visible = true
    end

    return true
end

---@param event EventData
function private.handle_delete_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type int
    local train_part_id = private.get_train_part_id(event.element)
    local train_part = storage.get_train_part(player, train_part_id)

    train_part.refs.element.destroy()
    storage.delete_train_part(player, train_part_id)

    return true
end

---@param event EventData
function private.handle_add_new_train_part(event)
    local player = game.get_player(event.player_index)
    ---@type LuaGuiElement
    local item_chooser = event.element
    ---@type LuaGuiElement
    local container = storage.get_container(player)

    if item_chooser.elem_value ~= nil and not private.is_last_train_part_empty(event.player_index) then
        public.append_component(container, player)
    end

    return true
end

---@param event EventData
function private.handle_change_locomotive_direction(event)
    local player = game.get_player(event.player_index)
    ---@type int
    local train_part_id = flib_gui.get_tags(event.element).train_part_id
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
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

function private.validator_rule_has_locomotive(data)
    for _, train_part in pairs(data.v) do
        if train_part.type == TRAIN_PART_TYPE.LOCOMOTIVE then
            return nil
        end
    end

    return {"validation-message.locomotive-required"}
end

---@param element LuaGuiElement
---@return int
function private.get_train_part_id(element)
    local tags = flib_gui.get_tags(element)

    return tags.train_part_id
end

---@param element LuaGuiElement
---@param player LuaPlayer
function private.get_locomotive_direction(element, player)
    local train_part_id = private.get_train_part_id(element)
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
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
function private.is_last_train_part_empty(player_index)
    local player = game.get_player(player_index)
    ---@type LuaGuiElement
    local container = storage.get_container(player)
    ---@type LuaGuiElement
    local last_train_part = container.children[#container.children]

    -- TODO
    return last_train_part.children[1].elem_value == nil
end

---@param choose_elem_button_element LuaGuiElement
---@return LuaGuiElement
function private.is_last_train_part_selector(choose_elem_button_element)
    -- TODO refactor
    local chooser_wrapper = choose_elem_button_element.parent
    local choosers_container = choose_elem_button_element.parent.parent

    return chooser_wrapper.get_index_in_parent() == #choosers_container.children
end

---@param value string|nil
---@return bool
function private.is_locomotive_selected(value)
    if value == nil then
        return false
    end

    local prototype = game.entity_prototypes[value]

    return prototype.type == "locomotive"
end

---@param item_selector LuaGuiElement
---@return bool
function private.is_train_part_selector_cleaned(item_selector)
    return item_selector.elem_value == nil and not private.is_last_train_part_selector(item_selector)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    storage.init()
end

function public.load()
end

---@param player LuaPlayer
function public.destroy(player)
    storage.destroy(player)
end

---@param container_element LuaGuiElement
---@param player LuaPlayer
function public.append_component(container_element, player)
    local train_part_id = script.generate_event_name()
    local refs = flib_gui.build(container_element, {build_structure.get(train_part_id)})

    storage.set_container(player, container_element)

    storage.add_train_part(player, train_part_id, refs)
end

---@return string
function public.name()
    return COMPONENT.NAME
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local event_handlers = {
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part,             func = private.handle_add_new_train_part },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part,             func = private.handle_update_train_part },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.change_locomotive_direction,    func = private.handle_change_locomotive_direction },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.delete_train_part,              func = private.handle_delete_train_part },
    }

    local processed = mod_event.dispatch(event_handlers, event, action)

    if processed then
        script.raise_event(
                mod.defines.events.on_mod_gui_form_changed,
                { player_index = event.player_index, target = mod.defines.gui.frames.add_group.name }
        )
    end

    return processed
end

---@param event EventData
function public.read_form(event)
    local player = game.get_player(event.player_index)
    local train_parts = storage.get_all_train_parts(player)

    local train = {}

    for i, el in pairs(train_parts) do
        local train_part = {}
        local part_chooser = el.refs.part_chooser
        local part_entity_type = part_chooser.elem_value

        if part_entity_type ~= nil then
            if private.is_locomotive_selected(part_entity_type) then
                train_part = {
                    type = TRAIN_PART_TYPE.LOCOMOTIVE,
                    entity = part_entity_type,
                    direction = private.get_locomotive_direction(part_chooser, player),
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
function public.validate_form(event)
    local form_data = public.read_form(event)
    local validator_rules = {
        {
            match = validator.match_by_name("train"),
            rules = { private.validator_rule_has_locomotive },
        },
    }

    return validator.validate(validator_rules, {train = form_data})
end

return public