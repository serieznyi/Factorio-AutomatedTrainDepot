local flib_gui = require("__flib__.gui")

local event_dispatcher = require("scripts.util.event_dispatcher")
local mod_gui = require("scripts.util.gui")
local depot = require("scripts.depot.depot")
local persistence_storage = require("scripts.persistence_storage")
local Context = require("scripts.lib.domain.Context")

local structure = require("scripts.gui.frame.main.component.train_template_view.structure")

local COMPONENT = {
    NAME = mod.defines.gui.components.train_template_view.name
}

local public = {}
local private = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.load()
    mod.global.gui.component[COMPONENT.NAME] = {}
end

---@param player LuaPlayer
function storage.clean(player)
    mod.global.gui.component[COMPONENT.NAME][player.index] = nil
end

---@param player LuaPlayer
---@param container LuaGuiElement
---@param refs table
function storage.set(player, container, refs)
    mod.global.gui.component[COMPONENT.NAME][player.index] = {
        container = container,
        refs = refs
    }
end

---@param player LuaPlayer
---@return table
function storage.refs(player)
    if mod.global.gui.component[COMPONENT.NAME][player.index] == nil then
        return nil
    end

    return mod.global.gui.component[COMPONENT.NAME][player.index].refs
end

---@param player LuaPlayer
---@return LuaGuiElement
function storage.container(player)
    return mod.global.gui.component[COMPONENT.NAME][player.index].container
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

function private.handle_enable_train_template(e)
    local player = game.get_player(e.player_index)

    if not private.can_handle_event(e) then
        return
    end

    local train_template_id = private.get_train_template_id(player)
    local train_template = depot.enable_train_template(train_template_id)

    private.refresh_component(player, train_template)

    return true
end

function private.handle_disable_train_template(e)
    local player = game.get_player(e.player_index)

    if not private.can_handle_event(e) then
        return
    end

    local train_template_id = private.get_train_template_id(player)
    local train_template = depot.disable_train_template(train_template_id)

    private.refresh_component(player, train_template)

    return true
end

function private.handle_change_trains_quantity(e)
    local player = game.get_player(e.player_index)

    if not private.can_handle_event(e) then
        return
    end

    local train_template_id = private.get_train_template_id(player)
    local count = private.get_train_quantity_change_value(e)
    local train_template = depot.change_trains_quantity(train_template_id, count)

    private.refresh_component(player, train_template)

    return true
end

function private.handle_refresh_component(e)
    local player = game.get_player(e.player_index)

    if not private.can_handle_event(e) then
        return
    end

    local train_template_id = private.get_train_template_id(player)
    local train_template = persistence_storage.get_train_template(train_template_id)

    private.refresh_component(player, train_template)

    return true
end

---@param e scripts.lib.decorator.Event
---@return bool
function private.can_handle_event(e)
    local player = game.get_player(e.player_index)
    local refs = storage.refs(player)

    return refs ~= nil and refs.component ~= nil and refs.component.valid
end

---@param player LuaPlayer
---@return uint
function private.get_train_template_id(player)
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

---@param train_template scripts.lib.domain.TrainTemplate
function private.train_template_component_caption(train_template)
    local icon = mod_gui.image_for_item(train_template.icon)

    return icon .. " " .. train_template.name
end

---@param player LuaPlayer
---@param train_template scripts.lib.domain.TrainTemplate
function private.refresh_component(player, train_template)
    local refs = storage.refs(player)
    ---@type LuaGuiElement
    local container = refs.train_view

    -- update title

    refs.component_title_label.caption = private.train_template_component_caption(train_template)

    -- update train parts view

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

    -- update quantity input

    refs.trains_quantity.text = tostring(train_template.trains_quantity)

    -- update control buttons

    refs.enable_button.enabled = not train_template.enabled
    refs.disable_button.enabled = train_template.enabled

    -- update tasks view

    local tasks_progress_container = refs.tasks_progress_container
    local context = Context.from_player(player)
    local tasks = persistence_storage.trains_tasks.find_forming_tasks(context, train_template.id)

    tasks_progress_container.clear()

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in ipairs(tasks) do
        flib_gui.add(tasks_progress_container, {
            type = "progressbar",
            value = task:progress() * 0.01
        })
    end
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
end

function public.load()
    storage.load()
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
    local refs = flib_gui.build(container, { structure.get(train_template)})

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
        {
            match = event_dispatcher.match_event(mod.defines.events.on_train_task_changed_mod),
            func = private.handle_refresh_component
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_train_template_changed_mod),
            func = private.handle_refresh_component
        },
    }

    return event_dispatcher.dispatch(event_handlers, event, COMPONENT.NAME, private.can_handle_event)
end

return public