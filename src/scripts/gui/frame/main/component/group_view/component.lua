local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")
local mod_gui = require("scripts.util.gui")

local build_structure = require("scripts.gui.frame.main.component.group_view.build_structure")

local COMPONENT = {
    NAME = "group_view"
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
---@param container LuaGuiElement
function storage.save_container(player, container)
    if global.gui.component[COMPONENT.NAME][player.index] == nil then
        global.gui.component[COMPONENT.NAME][player.index] = {
            container = container,
        }
    end
end

---@param player LuaPlayer
---@param refs table
function storage.save_gui(player, refs)
    global.gui.component[COMPONENT.NAME][player.index] = {
        refs = refs
    }
end

---@param player LuaPlayer
---@return table
function storage.get_gui(player)
    return global.gui.component[COMPONENT.NAME][player.index]
end

---@param player LuaPlayer
---@return LuaGuiElement
function storage.get_container(player)
    return global.gui.component[COMPONENT.NAME][player.index].container
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param player LuaPlayer
---@param train_group atd.TrainGroup
function private.refresh_train_view(player, train_group)
    local gui = storage.get_gui(player)
    local container = gui.refs.train_view

    mod_gui.clear_children(container)

    ---@param train_part atd.TrainPart
    for _, train_part in pairs(train_group.train) do

    flib_gui.add(container, {
            type = "sprite-button",
            enabled = false,
            style = "flib_selected_slot_default",
            sprite = mod_gui.image_path_for_item(train_part.entity),
        })
    end
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

---@return string
function public.name()
    return COMPONENT.NAME
end

---@param container LuaGuiElement
---@param train_group atd.TrainGroup
---@param player LuaPlayer
function public.create(container, player, train_group)
    local refs = flib_gui.build(container, {build_structure.get(train_group)})

    storage.save_container(player, container)

    storage.save_gui(player, refs)

    private.refresh_train_view(player, train_group)
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local event_handlers = {
        --{ target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part,             func = private.handle_add_new_train_part },
    }

    return mod_event.dispatch(event_handlers, event, action)
end

return public