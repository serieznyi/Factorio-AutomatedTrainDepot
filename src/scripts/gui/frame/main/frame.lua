local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")
local mod_event = require("scripts.util.event")

local constants = require("scripts.gui.frame.main.constants")
local build_structure = require("scripts.gui.frame.main.build_structure")

local FRAME = constants.FRAME
local ACTION = constants.ACTION

local storage = {
    init = function()
        mod.storage.gui[FRAME.NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        mod.storage.gui[FRAME.NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_gui = function(player)
        return mod.storage.gui[FRAME.NAME][player.index]
    end,
    ---@param player LuaPlayer
    ---@param refs table
    save_gui = function(player, refs)
        mod.storage.gui[FRAME.NAME][player.index] = {
            refs = refs,
        }
    end,
}

local frame = {}

---@param selected_element LuaGuiElement
---@param gui table
local function active_group_button(selected_element, gui)
    ---@param child LuaGuiElement
    for i, child in ipairs(gui.refs.groups_container.children) do
        if i ~= selected_element.get_index_in_parent() then
            flib_gui.update(child, {style = "atd_button_list_box_item"})
        else
            flib_gui.update(child, {style = "atd_button_list_box_item_active"})
        end
    end
end

---@param event EventData
local function select_group(event)
    local player = game.get_player(event.player_index)
    local gui = storage.get_gui(player)

    active_group_button(event.element, gui)

    gui.refs.edit_group_button.enabled = true
    gui.refs.delete_group_button.enabled = true
end

---@param event EventData
local function delete_group(event)
    local player = game.get_player(event.player_index)
    local gui = storage.get_gui(player)

    -- TODO
end

---@param player LuaPlayer
---@param container LuaGuiElement
local function populate_groups_list(player, container)
    -- todo get data from persistence
    if global.groups[player.surface.name] ~= nil then
        if global.groups[player.surface.name][player.force.name] ~= nil then
            mod_gui.clear_children(container)

            for _, group in pairs(global.groups[player.surface.name][player.force.name]) do
                local icon = mod_gui.image_from_item_name(group.icon)

                flib_gui.add(container, {
                    type = "button",
                    caption = icon .. " " .. group.name,
                    style = "atd_button_list_box_item",
                    actions = {
                        on_click = { target = FRAME.NAME, action = ACTION.GROUP_SELECTED}
                    }
                })
            end
        end
    end

    -- todo select first group
end

---@param event EventData
local function update_gui(event)
    local player = game.get_player(event.player_index)
    local gui = storage.get_gui(player)

    populate_groups_list(player, gui.refs.groups_container)
end

---@param player LuaPlayer
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, { build_structure.get() })

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    local resolution, scale = player.display_resolution, player.display_scale
    refs.window.location = {
        ((resolution.width - (FRAME.WIDTH * scale)) / 2),
        ((resolution.height - (FRAME.HEIGHT * scale)) / 2)
    }

    storage.save_gui(player, refs)

    return storage.get_gui(player)
end

---@return string
function frame.name()
    return FRAME.NAME
end

function frame.init()
    storage.init()
end

function frame.load()
    storage.init()
end

---@param player LuaPlayer
function frame.open(player)
    local gui = create_for(player)

    populate_groups_list(player, gui.refs.groups_container)

    local window = gui.refs.window
    window.bring_to_front()
    window.visible = true
    player.opened = window
end

---@param action table
---@param event EventData
function frame.dispatch(event, action)
    local handlers = {
        { target = FRAME.NAME, action = ACTION.CLOSE, func = frame.close },
        { target = FRAME.NAME, action = ACTION.GROUP_SELECTED, func = select_group },
        { target = FRAME.NAME, action = ACTION.DELETE_GROUP, func = delete_group },
        { event = mod.defines.events.on_mod_group_saved, func = update_gui },
    }

    return mod_event.dispatch(handlers, event, action)
end

function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = storage.get_gui(player)
    local window = gui.refs.window

    window.visible = false

    if player.opened == gui.refs.window then
        player.opened = nil
    end

    window.destroy()

    storage.destroy(player)

    return true
end

return frame