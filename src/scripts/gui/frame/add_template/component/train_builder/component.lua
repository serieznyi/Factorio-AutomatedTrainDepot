local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local TrainPart = require("lib.entity.TrainPart")

local mod_event = require("scripts.util.event")

local constants = require("scripts.gui.frame.add_template.component.train_builder.constants")
local build_structure = require("scripts.gui.frame.add_template.component.train_builder.build_structure")
local validator = require("scripts.gui.validator")

local COMPONENT = constants.COMPONENT

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

---@param event EventData
function private.handle_update_train_part(event)
    local player = game.get_player(event.player_index)
    local train_part_id = private.get_train_part_id(event.element)

    private.update_train_part(player, train_part_id)

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
        public.add_train_part(container, player)
    end

    return true
end

---@param event EventData
function private.handle_change_locomotive_direction(event)
    local player = game.get_player(event.player_index)
    local tags = flib_gui.get_tags(event.element)
    local train_part_id = private.get_train_part_id(event.element)
    local direction = tags.direction == mod.defines.train.direction.right and mod.defines.train.direction.left or mod.defines.train.direction.right

    private.set_locomotive_direction(train_part_id, player, direction)

    private.update_train_part(player, train_part_id)

    return true
end

---@param train_part_id uint
---@param player LuaPlayer
---@param new_direction uint
function private.set_locomotive_direction(train_part_id, player, new_direction)
    ---@type table
    local train_part = storage.get_train_part(player, train_part_id)
    local locomotive_direction_left_button = train_part.refs.locomotive_direction_left_button
    local locomotive_direction_right_button = train_part.refs.locomotive_direction_right_button
    flib_gui.update(locomotive_direction_left_button, { tags = { current_direction = new_direction } })
    flib_gui.update(locomotive_direction_right_button, { tags = { current_direction = new_direction } })
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
    local locomotive_direction_left_button = train_part.refs.locomotive_direction_left_button
    ---@type LuaGuiElement
    local locomotive_direction_right_button = train_part.refs.locomotive_direction_right_button
    ---@type uint
    local tags = flib_gui.get_tags(train_part.refs.locomotive_direction_right_button)
    local current_locomotive_direction = tags.current_direction

    if private.is_train_part_selector_cleaned(player, train_part_id) then
        train_part.refs.element.destroy()
        storage.delete_train_part(player, train_part_id)
        return
    end

    if part_chooser.elem_value == nil then
        return
    end

    local locomotive_part = private.is_locomotive_selected(part_chooser.elem_value)

    locomotive_config_button.visible = locomotive_part
    delete_button.visible = true

    if locomotive_part then
        locomotive_direction_left_button.visible = (current_locomotive_direction == mod.defines.train.direction.left)
        locomotive_direction_right_button.visible = (current_locomotive_direction == mod.defines.train.direction.right)

    end
end

function private.validator_rule_has_locomotive(data)
    for _, train_part in pairs(data.v) do
        if train_part.type == TrainPart.TYPE.LOCOMOTIVE then
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
function private.is_locomotive_selected(value)
    if value == nil then
        return false
    end

    local prototype = game.entity_prototypes[value]

    return prototype.type == "locomotive"
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

---@param train_part lib.entity.TrainPart
function private.write_form(player, refs, train_part)
    refs.part_chooser.elem_value = train_part.item_name

    if train_part.type == TrainPart.TYPE.LOCOMOTIVE then
        local train_part_id = private.get_train_part_id(refs.part_chooser)

        private.set_locomotive_direction(train_part_id, player, train_part.direction)
    elseif train_part.type == TrainPart.TYPE.CARGO then
        -- todo
    end
end

---@param container_element LuaGuiElement
---@param player LuaPlayer
---@param train_part lib.entity.TrainPart
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

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local event_handlers = {
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part,             func = private.handle_add_new_train_part },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part,             func = private.handle_update_train_part },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.change_locomotive_direction,    func = private.handle_change_locomotive_direction },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.delete_train_part,              func = private.handle_delete_train_part },
    }

    local processed = mod_event.dispatch(event_handlers, event, action, COMPONENT.NAME)

    if processed then
        script.raise_event(
                mod.defines.events.on_gui_form_changed_mod,
                { player_index = event.player_index, target = mod.defines.gui.frames.add_template.name }
        )
    end

    return processed
end

---@param event EventData
function public.read_form(event)
    local player = game.get_player(event.player_index)
    local train_parts = storage.get_train_parts(player)

    local train = {}

    for _, el in pairs(train_parts) do
        local part_chooser = el.refs.part_chooser
        local item_name = part_chooser.elem_value

        if item_name ~= nil then
            local locomotive = private.is_locomotive_selected(item_name)
            local type = locomotive and TrainPart.TYPE.LOCOMOTIVE or TrainPart.TYPE.CARGO
            ---@type lib.entity.TrainPart
            local train_part = TrainPart.new(type, item_name)

            if locomotive then
                train_part.direction = private.get_locomotive_direction(part_chooser, player)
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