local flib_gui = require("__flib__.gui")

local event_dispatcher = require("scripts.util.event_dispatcher")
local mod_gui = require("scripts.util.gui")
local depot = require("scripts.depot.depot")

local build_structure = require("scripts.gui.frame.main.component.train_template_view.build_structure")

local COMPONENT = {
    NAME = mod.defines.gui.components.train_template_view.name
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
function storage.clean(player)
    global.gui.component[COMPONENT.NAME][player.index] = nil
end

---@param player LuaPlayer
---@param container LuaGuiElement
---@param refs table
function storage.set(player, container, refs)
    global.gui.component[COMPONENT.NAME][player.index] = {
        container = container,
        refs = refs
    }
end

---@param player LuaPlayer
---@return table
function storage.refs(player)
    if global.gui.component[COMPONENT.NAME][player.index] == nil then
        return nil
    end

    return global.gui.component[COMPONENT.NAME][player.index].refs
end

---@param player LuaPlayer
---@return LuaGuiElement
function storage.container(player)
    return global.gui.component[COMPONENT.NAME][player.index].container
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@return uint
function private.get_train_id(player)
    local refs = storage.refs(player)
    local tags = flib_gui.get_tags(refs.component)

    return tags.train_template_id
end

---@param event scripts.lib.decorator.Event
---@return uint
function private.get_train_quantity_change_value(event)
    local action = flib_gui.read_action(event.original_event)

    return action.count
end

---@param player LuaPlayer
---@param train_template scripts.lib.domain.TrainTemplate
function private.refresh_component(player, train_template)
    local refs = storage.refs(player)
    ---@type LuaGuiElement
    local container = refs.train_view

    container.clear()

    ---@param train_part scripts.lib.domain.TrainPart
    for _, train_part in pairs(train_template.train) do
        flib_gui.add(container, {
            type = "sprite-button",
            enabled = false,
            style = "flib_slot_default",
            sprite = mod_gui.image_path_for_item(train_part.prototype_name),
        })
    end

    refs.trains_quantity.text = tostring(train_template.trains_quantity)

    refs.enable_button.enabled = not train_template.enabled
    refs.disable_button.enabled = train_template.enabled
end

function private.handle_enable_train_template(e)
    local player = game.get_player(e.player_index)
    local train_template_id = private.get_train_id(player)
    local train_template = depot.enable_train_template(train_template_id)

    private.refresh_component(player, train_template)

    return true
end

function private.handle_disable_train_template(e)
    local player = game.get_player(e.player_index)
    local train_template_id = private.get_train_id(player)
    local train_template = depot.disable_train_template(train_template_id)

    private.refresh_component(player, train_template)

    return true
end

function private.handle_change_trains_quantity(e)
    local player = game.get_player(e.player_index)
    local train_template_id = private.get_train_id(player)
    local count = private.get_train_quantity_change_value(e)
    local train_template = depot.change_trains_quantity(train_template_id, count)

    private.refresh_component(player, train_template)

    return true
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

---@return string
function public.name()
    return COMPONENT.NAME
end

---@param container LuaGuiElement
---@param train_template scripts.lib.domain.TrainTemplate
---@param player LuaPlayer
function public.create(container, player, train_template)
    local refs = flib_gui.build(container, {build_structure.get(train_template)})

    storage.set(player, container, refs)

    private.refresh_component(player, train_template)
end

---@param event scripts.lib.decorator.Event
function public.dispatch(event)
    local event_handlers = {
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.enable_train_template),
            func = private.handle_enable_train_template
        },
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.disable_train_template),
            func = private.handle_disable_train_template
        },
        {
            match = event_dispatcher.match_target_and_action(COMPONENT.NAME, mod.defines.gui.actions.change_trains_quantity),
            func = private.handle_change_trains_quantity
        },
    }

    return event_dispatcher.dispatch(event_handlers, event, COMPONENT.NAME)
end

return public