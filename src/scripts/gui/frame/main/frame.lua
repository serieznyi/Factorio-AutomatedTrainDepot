local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_gui = require("scripts.util.gui")
local Context = require("scripts.lib.domain.Context")
local event_dispatcher = require("scripts.util.event_dispatcher")
local persistence_storage = require("scripts.persistence_storage")

local structure = require("scripts.gui.frame.main.structure")
local train_template_view_component = require("scripts.gui.frame.main.component.train_template_view.component")
local trains_map_component = require("scripts.gui.frame.main.component.trains_map.component")
local ExtendedListBox = require("scripts.gui.component.extended_list_box.component")

local FRAME = {
    NAME = mod.defines.gui.frames.main.name,
    WIDTH = 1400,
    HEIGHT = 800,
}

---@type gui.component.ExtendedListBox
local trains_templates_list_component = nil
local public = {}
local private = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.load()
    mod.global.gui.frame[FRAME.NAME] = {}
end

function storage.clean()
    mod.global.gui.frame[FRAME.NAME] = nil
end

---@return table
function storage.refs()
    if mod.global.gui.frame[FRAME.NAME] == nil then
        return nil
    end

    return mod.global.gui.frame[FRAME.NAME].refs
end

---@param refs table
function storage.set_refs(refs)
    mod.global.gui.frame[FRAME.NAME] = {refs = refs}
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param event scripts.lib.decorator.Event
function private.handle_update_gui(event)
    local player = game.get_player(event.player_index)

    private.refresh_gui(player)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_open_uncontrolled_trains_map(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs()
    local context = Context.from_player(player)
    local trains = persistence_storage.find_uncontrolled_trains(context)

    refs.content_frame.clear()
    trains_map_component.create(refs.content_frame, player, trains)
end

---@param event scripts.lib.decorator.Event
function private.handle_delete_train_template(event)
    local player = game.get_player(event.player_index)

    local train_template_id = private.get_selected_train_template_id(player)

    persistence_storage.delete_train_template(train_template_id)

    train_template_view_component.destroy(player)

    trains_templates_list_component:remove_element(train_template_id)

    private.refresh_gui(player)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_close_frame(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs()
    local window = refs.window

    window.visible = false

    if player.opened == refs.window then
        player.opened = nil
    end

    mod.util.gui.frame_stack_pop(refs.window)

    window.destroy()

    storage.clean()

    return true
end

---@param player LuaPlayer
function private.select_train_template_view(player, train_template_id)
    local refs = storage.refs()

    local train_template = persistence_storage.get_train_template(train_template_id)

    if train_template == nil then
        return
    end

    refs.content_frame.clear()

    train_template_view_component.create(refs.content_frame, player, train_template)

    private.refresh_gui(player)
end

---@param tags table
function private.on_template_list_item_selected(event, tags)
    local player = game.get_player(event.player_index)

    private.select_train_template_view(player, tags.id)
end

---@return uint
function private.get_selected_train_template_id()
    return trains_templates_list_component:get_selected_id()
end

function private.refresh_control_buttons(player)
    local refs = storage.refs()
    local selected_train_template_id = trains_templates_list_component:get_selected_id()
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
    local context = Context.from_player(player)

    local new_values = private.get_trains_templates_values(context)
    trains_templates_list_component:refresh(new_values)

    private.refresh_control_buttons(player)
end

---@param context scripts.lib.domain.Context
---@return gui.component.ExtendedListBoxValue
function private.get_trains_templates_values(context)
    local trains_templates = persistence_storage.find_train_templates(context)

    ---@param t scripts.lib.domain.TrainTemplate
    return flib_table.map(
            trains_templates,
            function(t)
                local icon = mod_gui.image_for_item(t.icon)

                return {
                    caption = icon .. " " .. t.name,
                    id = t.id,
                    tooltip = { "main-frame.atd-train-template-list-button-tooltip", t.name},
                }
            end
    )
end

---@param player LuaPlayer
function private.create_for(player)
    local context = Context.from_player(player)
    local values = private.get_trains_templates_values(context)
    local structure_config = {frame_name = FRAME.NAME, width = FRAME.WIDTH, height = FRAME.HEIGHT}
    local refs = flib_gui.build(player.gui.screen, { structure.get(structure_config) })

    trains_templates_list_component = ExtendedListBox.new(
            values,
            nil,
            nil,
            private.on_template_list_item_selected
    )
    trains_templates_list_component:build(refs.trains_templates_container)

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    local resolution, scale = player.display_resolution, player.display_scale
    refs.window.location = {
        ((resolution.width - (FRAME.WIDTH * scale)) / 2),
        ((resolution.height - (FRAME.HEIGHT * scale)) / 2)
    }

    storage.set_refs(refs)

    mod.util.gui.frame_stack_push(refs.window)

    return storage.refs()
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@return string
function public.name()
    return FRAME.NAME
end

function public.init()
    train_template_view_component.init()
    trains_map_component.init()
end

function public.load()
    storage.load()
    train_template_view_component.load()
    trains_map_component.load()
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

---@param event scripts.lib.decorator.Event
function public.dispatch(event)
    local handlers = {
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.close_frame),
            func = private.handle_close_frame
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.select_train_template),
            func = private.handle_select_train_template
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.open_uncontrolled_trains_map),
            func = private.handle_open_uncontrolled_trains_map
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.delete_train_template),
            func = private.handle_delete_train_template
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_train_template_changed_mod),
            func = private.handle_update_gui,
        },
        {
            match = event_dispatcher.match_target(train_template_view_component.name()),
            func = train_template_view_component.dispatch
        },
        {
            match = event_dispatcher.match_all_non_gui_events(),
            func = train_template_view_component.dispatch
        },
        {
            match = function()
                return trains_templates_list_component and event_dispatcher.match_target(trains_templates_list_component:name())
            end,
            func = function(e)
                if trains_templates_list_component == nil then
                    return false
                end

                return trains_templates_list_component:dispatch(e)
            end
        },
    }

    return event_dispatcher.dispatch(handlers, event, FRAME.NAME)
end

return public