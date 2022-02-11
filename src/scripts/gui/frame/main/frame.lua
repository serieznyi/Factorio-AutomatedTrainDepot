local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")
local Context = require("scripts.lib.domain.Context")
local mod_event = require("scripts.util.event")
local persistence_storage = require("scripts.persistence_storage")

local constants = require("scripts.gui.frame.main.constants")
local build_structure = require("scripts.gui.frame.main.build_structure")
local train_template_view_component = require("scripts.gui.frame.main.component.train_template_view.component")
local trains_view_component = require("scripts.gui.frame.main.component.trains_view.component")

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
function storage.clean(player)
    global.gui.frame[FRAME.NAME][player.index] = nil
end

---@param player LuaPlayer
---@return table
function storage.refs(player)
    if global.gui.frame[FRAME.NAME][player.index] == nil then
        return nil
    end

    return global.gui.frame[FRAME.NAME][player.index].refs
end

---@param player LuaPlayer
---@param refs table
function storage.set(player, refs)
    global.gui.frame[FRAME.NAME][player.index] = {
        refs = refs,
    }
end

---@param player LuaPlayer
function storage.get_selected_train_template(player)
    return global.gui.frame[FRAME.NAME][player.index].selected_train_template
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

function private.handle_open_uncontrolled_trains_view(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local context = Context.from_player(player)
    local trains = persistence_storage.find_uncontrolled_trains(context)

    refs.content_frame.clear()
    trains_view_component.create(refs.content_frame, player, trains)
end

---@param event EventData
function private.handle_select_train_template(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)

    private.mark_selected_train_template_button(event.element, refs)

    local train_template_id = private.get_selected_train_template_id(player)
    local train_template = persistence_storage.get_train_template(train_template_id)

    refs.content_frame.clear()

    train_template_view_component.create(refs.content_frame, player, train_template)

    private.refresh_gui(player)

    return true
end

---@param event EventData
function private.handle_delete_train_template(event)
    local player = game.get_player(event.player_index)
    local selected_train_template_element = private.get_selected_train_template_element(player)

    if selected_train_template_element ~= nil then
        local train_template_id = private.get_selected_train_template_id(player)

        persistence_storage.delete_train_template(train_template_id)

        selected_train_template_element.destroy()
    end

    private.refresh_gui(player)

    return true
end

---@param event EventData
function private.handle_close_frame(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local window = refs.window

    window.visible = false

    if player.opened == refs.window then
        player.opened = nil
    end

    window.destroy()

    storage.clean(player)

    return true
end

---@param player LuaPlayer
function private.get_selected_train_template_element(player)
    local refs = storage.refs(player)

    for _, v in ipairs(refs.trains_templates_container.children) do
        local tags = flib_gui.get_tags(v)

        if tags.selected == true then
            return v
        end
    end

    return nil
end

---@param player LuaPlayer
---@return uint
function private.get_selected_train_template_id(player)
    local selected_train_template_element = private.get_selected_train_template_element(player)

    if selected_train_template_element == nil then
        return nil
    end

    local selected_train_template_element_tags = flib_gui.get_tags(selected_train_template_element)

    return selected_train_template_element_tags.train_template_id
end

---@param player LuaPlayer
---@param container LuaGuiElement
function private.refresh_trains_templates_list(player, container)
    local context = Context.from_player(player)
    local trains_templates = persistence_storage.find_train_templates(context)
    local selected_train_template_id = private.get_selected_train_template_id(player)

    container.clear()

    ---@param train_template scripts.lib.domain.TrainTemplate
    for i, train_template in pairs(trains_templates) do
        local icon = mod_gui.image_for_item(train_template.icon)
        local selected_train_template = train_template.id == selected_train_template_id

        if selected_train_template_id == nil and i == 1 then
            selected_train_template = true
        end

        flib_gui.add(container, {
            type = "button",
            caption = icon .. " " .. train_template.name,
            style = selected_train_template and "atd_button_list_box_item_active" or "atd_button_list_box_item",
            tooltip = { "main-frame.atd-train-template-list-button-tooltip", train_template.name},
            tags = { train_template_id = train_template.id, selected = selected_train_template },
            actions = {
                on_click = { target = FRAME.NAME, action = mod.defines.gui.actions.select_train_template }
            }
        })
    end
end

function private.refresh_control_buttons(player)
    local refs = storage.refs(player)
    local selected_train_template_id = private.get_selected_train_template_id(player)
    local train_template_selected = selected_train_template_id ~= nil
    local context = Context.from_player(player)
    local has_uncontrolled_trains = persistence_storage.count_uncontrolled_trains(context) > 0

    refs.edit_button.enabled = train_template_selected
    refs.delete_button.enabled = train_template_selected
    refs.show_uncontrolled_trains_button.enabled = has_uncontrolled_trains

    if train_template_selected then
        -- todo сделать так же для delete
        flib_gui.update(refs.edit_button, { tags = { train_template_id = selected_train_template_id } })
    end
end

---@param player LuaPlayer
function private.refresh_gui(player)
    local refs = storage.refs(player)

    private.refresh_trains_templates_list(player, refs.trains_templates_container)

    private.refresh_control_buttons(player)
end

---@param selected_element LuaGuiElement
---@param refs table
function private.mark_selected_train_template_button(selected_element, refs)
    local element_index = selected_element.get_index_in_parent()

    ---@param child LuaGuiElement
    for i, child in ipairs(refs.trains_templates_container.children) do
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

    storage.set(player, refs)

    return storage.refs(player)
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
    train_template_view_component.init()
    trains_view_component.init()
end

function public.load()
    train_template_view_component.load()
    trains_view_component.load()
end

---@param player LuaPlayer
function public.open(player)
    local refs = private.create_for(player)

    private.refresh_gui(player)

    ---@type LuaGuiElement
    local window = refs.window
    window.bring_to_front()
    window.visible = true
    player.opened = window
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local handlers = {
        { target = train_template_view_component.name(), action = mod.defines.gui.actions.any, func = train_template_view_component.dispatch },
        { target = FRAME.NAME, action = mod.defines.gui.actions.close_frame, func = private.handle_close_frame },
        { target = FRAME.NAME, action = mod.defines.gui.actions.select_train_template, func = private.handle_select_train_template },
        { target = FRAME.NAME, action = mod.defines.gui.actions.open_uncontrolled_trains_view, func = private.handle_open_uncontrolled_trains_view },
        { target = FRAME.NAME, action = mod.defines.gui.actions.delete_train_template, func = private.handle_delete_train_template },
        -- todo
        { target = FRAME.NAME, event = mod.defines.events.on_train_template_saved_mod, func = private.handle_update_gui },
    }

    return mod_event.dispatch(handlers, event, action, FRAME.NAME)
end

return public