local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")
local mod_gui = require("scripts.util.gui")
local depot = require("scripts.depot.depot")

local build_structure = require("scripts.gui.frame.main.component.group_view.build_structure")

local COMPONENT = {
    NAME = mod.defines.gui.components.group_view.name
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
---@param train_group atd.TrainGroup
function private.refresh_train_view(player, train_group)
    local refs = storage.refs(player)
    local container = refs.train_view

    mod_gui.clear_children(container)

    ---@param train_part atd.TrainPart
    for _, train_part in pairs(train_group.train) do
        flib_gui.add(container, {
            type = "sprite-button",
            enabled = false,
            style = "flib_slot_default",
            sprite = mod_gui.image_path_for_item(train_part.entity),
        })
    end

    refs.enable_button.enabled = not train_group.enabled
    refs.disable_button.enabled = train_group.enabled
end

function private.handle_enable_train_group(e)
    local player = game.get_player(e.player_index)
    local refs = storage.refs(player)
    local tags = flib_gui.get_tags(refs.component)
    local train_group_id = tags.train_group_id
    local train_group = depot.enable_train_group(player, train_group_id)

    private.refresh_train_view(player, train_group)

    return true
end

function private.handle_disable_train_group(e)
    local player = game.get_player(e.player_index)
    local refs = storage.refs(player)
    local tags = flib_gui.get_tags(refs.component)
    local train_group_id = tags.train_group_id
    local train_group = depot.disable_train_group(player, train_group_id)

    private.refresh_train_view(player, train_group)

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
---@param train_group atd.TrainGroup
---@param player LuaPlayer
function public.create(container, player, train_group)
    local refs = flib_gui.build(container, {build_structure.get(train_group)})

    storage.set(player, container, refs)

    private.refresh_train_view(player, train_group)
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local event_handlers = {
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.enable_train_group, func = private.handle_enable_train_group },
        { target = COMPONENT.NAME, action = mod.defines.gui.actions.disable_train_group, func = private.handle_disable_train_group },
    }

    return mod_event.dispatch(event_handlers, event, action, COMPONENT.NAME)
end

return public