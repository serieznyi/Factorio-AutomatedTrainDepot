local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")

local constants = require("scripts.gui.frame.main.constants")
local build_structure = require("scripts.gui.frame.main.build_structure")

local FRAME = constants.FRAME
local ACTION = constants.ACTION

local persistence = {
    init = function()
        global.gui[FRAME.NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui[FRAME.NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_gui = function(player)
        return global.gui[FRAME.NAME][player.index]
    end,
    ---@param player LuaPlayer
    ---@param refs table
    save_gui = function(player, refs)
        global.gui[FRAME.NAME][player.index] = {
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
    local gui = persistence.get_gui(player)

    active_group_button(event.element, gui)

    gui.refs.edit_group_button.enabled = true
    gui.refs.delete_group_button.enabled = true
end

---@param event EventData
local function delete_group(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

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
                        on_click = { gui = FRAME.NAME, action = ACTION.GROUP_SELECTED}
                    }
                })
            end
        end
    end

    -- todo select first group
end

---@param player LuaPlayer
local function update_gui(player)
    local gui = persistence.get_gui(player)

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

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
end

---@return table
function frame.remote_interfaces()
    return {
        ---@param player LuaPlayer
        update = function(player) update_gui(player) end,
    }
end

---@return string
function frame.name()
    return FRAME.NAME
end

function frame.init()
    persistence.init()
end

function frame.load()
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
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME.NAME, action = ACTION.CLOSE, func = function(_, e) return frame.close(e) end},
        { gui = FRAME.NAME, action = ACTION.GROUP_SELECTED, func = function(_, e) return select_group(e) end},
        { gui = FRAME.NAME, action = ACTION.DELETE_GROUP, func = function(_, e) return delete_group(e) end},
    }

    for _, h in ipairs(event_handlers) do
        if h.gui == action.gui and (h.action == action.action or h.action == nil) then
            if h.func(action, event) then
                processed = true
            end
        end
    end

    return processed
end

function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)
    local window = gui.refs.window

    window.visible = false

    if player.opened == gui.refs.window then
        player.opened = nil
    end

    window.destroy()

    persistence.destroy(player)

    return true
end

return frame