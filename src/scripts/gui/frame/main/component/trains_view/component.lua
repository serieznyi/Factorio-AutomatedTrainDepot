local flib_gui = require("__flib__.gui")

local mod_event = require("scripts.util.event")
local mod_gui = require("scripts.util.gui")
local depot = require("scripts.depot.depot")

local build_structure = require("scripts.gui.frame.main.component.trains_view.build_structure")

local COMPONENT = {
    NAME = mod.defines.gui.components.trains_view.name
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
---@param trains table
function private.refresh_component(player, trains)
    local refs = storage.refs(player)
    local trains_table = refs.trains_table

    -- todo replace on .clean()
    mod_gui.clear_children(trains_table)

    -----@param train atd.Train
    for _, train in ipairs(trains) do
        local locomotive = train.train.locomotives.front_movers[1]

        flib_gui.add(trains_table, {
            type = "frame",
            style = "train_with_minimap_frame",
            children = {
                {
                    type = "minimap",
                    entity = locomotive,
                }
            }
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
    storage.clean(player)
end

---@return string
function public.name()
    return COMPONENT.NAME
end

---@param container LuaGuiElement
---@param trains table
---@param player LuaPlayer
function public.create(container, player, trains)
    -- todo add real caption
    local caption = {"train-view.some-caption"}
    local refs = flib_gui.build(container, {build_structure.get(caption)})

    storage.set(player, container, refs)

    private.refresh_component(player, trains)
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local event_handlers = {
        --{ target = COMPONENT.NAME, action = mod.defines.gui.actions.enable_train_template, func = private.handle_enable_train_template },
    }

    return mod_event.dispatch(event_handlers, event, action, COMPONENT.NAME)
end

return public