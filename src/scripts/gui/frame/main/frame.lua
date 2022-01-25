local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")
local mod_event = require("scripts.util.event")
local repository = require("scripts.repository")

local constants = require("scripts.gui.frame.main.constants")
local build_structure = require("scripts.gui.frame.main.build_structure")

local FRAME = constants.FRAME

local public = {}
local private = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.init()
    global.gui.frame[FRAME.NAME] = {}
end

---@param player LuaPlayer
function storage.destroy(player)
    global.gui.frame[FRAME.NAME][player.index] = nil
end

---@param player LuaPlayer
---@return table
function storage.get_gui(player)
    return global.gui.frame[FRAME.NAME][player.index]
end

---@param player LuaPlayer
---@param refs table
function storage.save_gui(player, refs)
    global.gui.frame[FRAME.NAME][player.index] = {
        refs = refs,
    }
end

---@param player LuaPlayer
function storage.get_selected_group(player)
    return global.gui.frame[FRAME.NAME][player.index].selected_group
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param event EventData
function private.handle_update_gui(event)
    local player = game.get_player(event.player_index)

    private.refresh_gui(player)

    return true
end

---@param event EventData
function private.handle_select_group(event)
    local player = game.get_player(event.player_index)
    local gui = storage.get_gui(player)

    private.mark_selected_group_button(event.element, gui)

    private.refresh_gui(player)

    return true
end

---@param event EventData
function private.handle_delete_group(event)
    local player = game.get_player(event.player_index)
    local selected_group_element = private.get_selected_group_element(player)

    if selected_group_element ~= nil then
        local group_id = private.get_selected_group_id(player)

        repository.delete_group(player, group_id)

        selected_group_element.destroy()
    end

    private.refresh_gui(player)

    return true
end

---@param player LuaPlayer
function private.get_selected_group_element(player)
    local gui = storage.get_gui(player)

    for _, v in ipairs(gui.refs.groups_container.children) do
        local tags = flib_gui.get_tags(v)

        if tags.selected == true then
            return v
        end
    end

    return nil
end

---@param player LuaPlayer
function private.get_selected_group_id(player)
    local selected_group_element = private.get_selected_group_element(player)

    if selected_group_element == nil then
        return nil
    end

    local selected_group_element_tags = flib_gui.get_tags(selected_group_element)

    return  selected_group_element_tags.group_id
end

---@param player LuaPlayer
---@param container LuaGuiElement
function private.refresh_groups_list(player, container)
    local groups = repository.find_all(player)
    local selected_group_id = private.get_selected_group_id(player)

    mod_gui.clear_children(container)

    for i, group in pairs(groups) do
        local icon = mod_gui.image_for_item(group.icon)
        local group_selected = group.id == selected_group_id

        if selected_group_id == nil and i == 1 then
            group_selected = true
        end

        flib_gui.add(container, {
            type = "button",
            caption = icon .. " " .. group.name,
            style = group_selected and "atd_button_list_box_item_active" or "atd_button_list_box_item",
            tags = { group_id = group.id, selected = group_selected },
            actions = {
                on_click = { target = FRAME.NAME, action = mod.defines.gui.actions.select_group }
            }
        })
    end
end

function private.refresh_groups_control_buttons(player)
    local gui = storage.get_gui(player)
    local selected_group_id = private.get_selected_group_id(player)
    local group_selected = selected_group_id ~= nil

    gui.refs.edit_group_button.enabled = group_selected
    gui.refs.delete_group_button.enabled = group_selected

    if group_selected then
        -- todo сделать так же для delete
        flib_gui.update(gui.refs.edit_group_button, { tags = { group_id = selected_group_id } })
    end
end

---@param player LuaPlayer
function private.refresh_gui(player)
    local gui = storage.get_gui(player)

    private.refresh_groups_list(player, gui.refs.groups_container)

    private.refresh_groups_control_buttons(player)
end

---@param player LuaPlayer
---@param selected_element LuaGuiElement
---@param gui table
function private.mark_selected_group_button(selected_element, gui)
    local element_index = selected_element.get_index_in_parent()

    ---@param child LuaGuiElement
    for i, child in ipairs(gui.refs.groups_container.children) do
        if i ~= element_index then
            flib_gui.update(child, { tags = {selected = false} })
        else
            flib_gui.update(child, { tags = {selected = true} })
        end
    end
end

---@param player LuaPlayer
function private.create_for(player)
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

function private.close_frame(event)
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

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@return string
function public.name()
    return FRAME.NAME
end

function public.init()
    storage.init()
end

function public.load()
end

---@param player LuaPlayer
function public.open(player)
    local gui = private.create_for(player)

    private.refresh_groups_list(player, gui.refs.groups_container)

    local window = gui.refs.window
    window.bring_to_front()
    window.visible = true
    player.opened = window
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local handlers = {
        { target = FRAME.NAME, action = mod.defines.gui.actions.close_frame,    func = private.close_frame },
        { target = FRAME.NAME, action = mod.defines.gui.actions.select_group,   func = private.handle_select_group },
        { target = FRAME.NAME, action = mod.defines.gui.actions.delete_group,   func = private.handle_delete_group },
        -- todo
        { target = FRAME.NAME, event = mod.defines.events.on_mod_group_saved,   func = private.handle_update_gui },
    }

    return mod_event.dispatch(handlers, event, action)
end

return public