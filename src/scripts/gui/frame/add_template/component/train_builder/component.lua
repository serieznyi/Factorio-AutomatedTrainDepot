local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local TrainPart = require("scripts.lib.domain.TrainPart")

local event_dispatcher = require("scripts.util.event_dispatcher")

local constants = require("scripts.gui.frame.add_template.component.train_builder.constants")
local build_structure = require("scripts.gui.frame.add_template.component.train_builder.build_structure")
local validator = require("scripts.gui.validator")

local COMPONENT = constants.COMPONENT
local on_changed_callback = function()  end
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
function storage.clean(player)
    global.gui.component[COMPONENT.NAME][player.index] = nil
end

---@param player LuaPlayer
---@return table
function storage.get_train_parts(player)
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
    else
        global.gui.component[COMPONENT.NAME][player.index].container = container
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
    global.gui.component[COMPONENT.NAME][player.index].train_parts[train_part_id] = { refs = refs }
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

---@param e scripts.lib.decorator.Event
---@return bool
function private.can_handle_event(e)
    local player = game.get_player(e.player_index)
    local container = storage.get_container(player)

    return container ~= nil and container.valid
end

---@param event scripts.lib.decorator.Event
function private.handle_update_train_part(event)
    local player = game.get_player(event.player_index)

    if not private.can_handle_event(event) then
        return
    end

    local train_part_id = private.get_train_part_id(event.gui_element)

    private.update_train_part(player, train_part_id)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_delete_train_part(event)
    local player = game.get_player(event.player_index)

    if not private.can_handle_event(event) then
        return
    end

    ---@type int
    local train_part_id = private.get_train_part_id(event.gui_element)
    local train_part = storage.get_train_part(player, train_part_id)

    train_part.refs.element.destroy()
    storage.delete_train_part(player, train_part_id)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_add_new_train_part(event)
    local player = game.get_player(event.player_index)

    if not private.can_handle_event(event) then
        return
    end

    ---@type LuaGuiElement
    local item_chooser = event.gui_element
    ---@type LuaGuiElement
    local container = storage.get_container(player)

    if item_chooser.elem_value ~= nil and not private.is_last_train_part_empty(event.player_index) then
        public.add_train_part(container, player)
    end

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_change_carrier_direction(event)
    local player = game.get_player(event.player_index)

    if not private.can_handle_event(event) then
        return
    end

    local tags = flib_gui.get_tags(event.gui_element)
    local train_part_id = private.get_train_part_id(event.gui_element)
    local direction = tags.direction == mod.defines.train.direction.opposite_direction and mod.defines.train.direction.in_direction or mod.defines.train.direction.opposite_direction

    private.set_carrier_direction(train_part_id, player, direction)

    private.update_train_part(player, train_part_id)

    return true
end

---@param train_part_id uint
---@param player LuaPlayer
---@param new_direction uint
function private.set_carrier_direction(train_part_id, player, new_direction)
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
    local direction_left_button = train_part.refs.carrier_direction_left_button
    local direction_right_button = train_part.refs.carrier_direction_right_button
    flib_gui.update(direction_left_button, { tags = { current_direction = new_direction } })
    flib_gui.update(direction_right_button, { tags = { current_direction = new_direction } })
end

---@param player LuaPlayer
---@param train_part_id uint
function private.update_train_part(player, train_part_id)
    local train_part = storage.get_train_part(player, train_part_id)
    ---@type LuaGuiElement
    local delete_button = train_part.refs.delete_button
    ---@type LuaGuiElement
    local part_chooser = train_part.refs.part_chooser
    ---@type LuaGuiElement
    local locomotive_config_button = train_part.refs.locomotive_config_button
    ---@type LuaGuiElement
    local direction_left_button = train_part.refs.carrier_direction_left_button
    ---@type LuaGuiElement
    local direction_right_button = train_part.refs.carrier_direction_right_button
    ---@type uint
    local tags = flib_gui.get_tags(train_part.refs.carrier_direction_right_button)
    local current_carrier_direction = tags.current_direction

    if private.is_train_part_selector_cleaned(player, train_part_id) then
        train_part.refs.element.destroy()
        storage.delete_train_part(player, train_part_id)
        return
    end

    if part_chooser.elem_value == nil then
        return
    end

    local type = private.get_train_part_type_from_item_name(part_chooser.elem_value)
    local has_direction = type ~= TrainPart.TYPE.CARGO

    locomotive_config_button.visible = type == TrainPart.TYPE.LOCOMOTIVE
    delete_button.visible = true

    if has_direction then
        direction_left_button.visible = (current_carrier_direction == mod.defines.train.direction.in_direction)
        direction_right_button.visible = (current_carrier_direction == mod.defines.train.direction.opposite_direction)
    end
end

function private.validator_rule_has_main_locomotive(field_name, form)
    ---@type scripts.lib.domain.TrainPart
    local carrier = form[field_name][1]

    if not carrier or carrier.type == TrainPart.TYPE.LOCOMOTIVE then
        return
    end

    return {"validation-message.first-carrier-must-be-locomotive"}
end

function private.validator_rule_main_locomotive_wrong_direction(field_name, form)
    ---@type scripts.lib.domain.TrainPart
    local carrier = form[field_name][1]

    if not carrier or carrier.type ~= TrainPart.TYPE.LOCOMOTIVE then
        return
    end

    if carrier.direction == mod.defines.train.direction.in_direction then
        return
    end

    return {"validation-message.locomotive-direction-in-station"}
end

---@param element LuaGuiElement
---@return int
function private.get_train_part_id(element)
    local tags = flib_gui.get_tags(element)

    return tags.train_part_id
end

---@param element LuaGuiElement
---@param player LuaPlayer
function private.get_carrier_direction(element, player)
    local train_part_id = private.get_train_part_id(element)
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
    local left_button = train_part.refs.carrier_direction_left_button
    local right_button = train_part.refs.carrier_direction_right_button

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

    -- TODO make this part more clearly
    return last_train_part.children[1].elem_value == nil
end

---@param player LuaPlayer
---@param train_part_id uint
---@return bool
function private.is_last_train_part_selector(player, train_part_id)
    local train_part = storage.get_train_part(player, train_part_id)
    local component = storage.get_container(player)
    ---@type LuaGuiElement
    local element = train_part.refs.element

    return element.get_index_in_parent() == #component.children
end

---@param value string|nil
---@return bool
function private.get_train_part_type_from_item_name(value)
    assert(value, "value is nil")

    local prototype = game.entity_prototypes[value]

    local map = {
        ["locomotive"] = TrainPart.TYPE.LOCOMOTIVE,
        ["artillery-wagon"] = TrainPart.TYPE.ARTILLERY,
        ["cargo-wagon"] = TrainPart.TYPE.CARGO,
        ["fluid-wagon"] = TrainPart.TYPE.CARGO,
    }

    return map[prototype.type]
end

---@param player LuaPlayer
---@param train_part_id uint
---@return bool
function private.is_train_part_selector_cleaned(player, train_part_id)
    local train_part = storage.get_train_part(player, train_part_id)

    return train_part.refs.part_chooser.elem_value == nil and not private.is_last_train_part_selector(player, train_part_id)
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
    storage.clean(player)
end

---@param train_part scripts.lib.domain.TrainPart
function private.write_form(player, refs, train_part)
    refs.part_chooser.elem_value = train_part.prototype_name

    if train_part.type == TrainPart.TYPE.LOCOMOTIVE or train_part.type == TrainPart.TYPE.ARTILLERY then
        local train_part_id = private.get_train_part_id(refs.part_chooser)

        private.set_carrier_direction(train_part_id, player, train_part.direction)
    end
end

---@param container_element LuaGuiElement
---@param player LuaPlayer
---@param train_part scripts.lib.domain.TrainPart
function public.add_train_part(container_element, player, train_part)
    -- todo use math rand
    local train_part_id = script.generate_event_name()
    local refs = flib_gui.build(container_element, {build_structure.get(train_part_id)})

    storage.set_container(player, container_element)

    storage.add_train_part(player, train_part_id, refs)

    if train_part ~= nil then
        private.write_form(player, refs, train_part)
        private.update_train_part(player, train_part_id)
    end
end

---@return string
function public.name()
    return COMPONENT.NAME
end

---@param event scripts.lib.decorator.Event
function public.dispatch(event)
    local event_handlers = {
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.refresh_train_part),
            func = private.handle_add_new_train_part
        },
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.refresh_train_part),
            func = private.handle_update_train_part
        },
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.change_carrier_direction),
            func = private.handle_change_carrier_direction
        },
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.delete_train_part),
            func = private.handle_delete_train_part
        },
    }

    local processed = event_dispatcher.dispatch(event_handlers, event, COMPONENT.NAME)

    if processed then
        on_changed_callback(event) -- todo use event ?
    end

    return processed
end

---@param player LuaPlayer
function public.read_form(player)
    local train_parts = storage.get_train_parts(player)

    local train = {}

    for _, el in pairs(train_parts) do
        local part_chooser = el.refs.part_chooser
        local item_name = part_chooser.elem_value

        if item_name ~= nil then
            local type = private.get_train_part_type_from_item_name(item_name)
            ---@type scripts.lib.domain.TrainPart
            local train_part = TrainPart.new(type, item_name)

            if type == TrainPart.TYPE.ARTILLERY then
                train_part.direction = private.get_carrier_direction(part_chooser, player)
            elseif type == TrainPart.TYPE.LOCOMOTIVE then
                train_part.direction = private.get_carrier_direction(part_chooser, player)
                train_part.use_any_fuel = true
                -- todo add later
                --train_part.fuel = {
                --    {type = "coal", amount = 1},
                --    {type = "coal", amount = 1},
                --    {type = "coal", amount = 1},
                --}
                --train_part.inventory = {
                --    {entity = "entity1"},
                --    {entity = "entity2"},
                --    {entity = "entity3"},
                --}
            end

            table.insert(train, train_part)
        end
    end

    return train
end

function public.on_changed(callback)
    on_changed_callback = callback
end

---@param player LuaPlayer
function public.validate_form(player)
    local form_data = public.read_form(player)
    local validator_rules = {
        {
            match = validator.match_by_name({"train"}),
            rules = { private.validator_rule_has_main_locomotive },
        },
        {
            match = validator.match_by_name({"train"}),
            rules = { private.validator_rule_main_locomotive_wrong_direction },
        },
    }

    return validator.validate(validator_rules, {train = form_data})
end

return public