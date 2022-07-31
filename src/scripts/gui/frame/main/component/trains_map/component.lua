local flib_gui = require("__flib__.gui")

local event_dispatcher = require("scripts.util.event_dispatcher")

local structure = require("scripts.gui.frame.main.component.trains_map.structure")

local COMPONENT = {
    NAME = mod.defines.gui.components.trains_map.name
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
    ---@type LuaGuiElement
    local trains_table = refs.trains_table

    trains_table.clear()

    -----@param train scripts.lib.domain.Train
    for _, train in ipairs(trains) do
        local locomotive = train:get_main_locomotive()

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
    assert(container, "container is nil")
    assert(player, "player is nil")

    local caption = {"trains-map.atd-uncontrolled-trains"}
    local refs = flib_gui.build(container, { structure.get(caption)})

    storage.set(player, container, refs)

    private.refresh_component(player, trains)
end

---@param event scripts.lib.decorator.Event
function public.dispatch(event)
    local event_handlers = {

    }

    return event_dispatcher.dispatch(event_handlers, event, COMPONENT.NAME)
end

return public