local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local event_dispatcher = require("scripts.util.event_dispatcher")
local Context = require("scripts.lib.domain.Context")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.component")
local DepotSettings = require("scripts.lib.domain.DepotSettings")
local persistence_storage = require("scripts.persistence_storage")
local structure = require("scripts.gui.frame.settings.structure")
local validator = require("scripts.gui.validator")
local TrainScheduleSelector = require("scripts.gui.component.train_schedule_selector.component")

local FRAME = {
    NAME = mod.defines.gui.frames.settings.name,
}
---@type gui.component.TrainStationSelector
local clean_train_station_dropdown_component
---@type gui.component.TrainScheduleSelector
local train_schedule_component

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

function storage.set(player, refs)
    global.gui.frame[FRAME.NAME][player.index] = {
        refs = refs,
    }
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param event scripts.lib.decorator.Event
function private.handle_form_changed(event)
    local player = game.get_player(event.player_index)

    private.update_form(player)

    return true
end

---@param player LuaPlayer
function private.update_form(player)
    local refs = storage.refs(player)
    local submit_button = refs.submit_button
    local validation_errors = private.validate_form(player)

    submit_button.enabled = #validation_errors == 0
    validator.render_errors(refs.validation_errors_container, validation_errors)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_save_form(event)
    local player = game.get_player(event.player_index)
    local form_data = private.read_form(player)
    local validation_errors = private.validate_form(player)

    if #validation_errors == 0 then
        persistence_storage.set_depot_settings(DepotSettings.from_table(form_data))
    end

    private.destroy_frame(player)

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_open_frame(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)

    if refs == nil then
        refs = private.create_for(player)
    end

    private.update_form(player)

    refs.window.bring_to_front()
    refs.window.visible = true
    player.opened = refs.window

    return true
end

---@param event scripts.lib.decorator.Event
function private.handle_frame_destroy(event)
    local player = game.get_player(event.player_index)

    private.destroy_frame(player)

    return true
end

function private.validation_rules()
    return {}
end

function private.destroy_frame(player)
    local refs = storage.refs(player)

    if refs == nil then
        return
    end

    local window = refs.window

    window.visible = false
    window.destroy()

    clean_train_station_dropdown_component = nil
    train_schedule_component = nil

    storage.clean(player)
end

---@param player LuaPlayer
---@param refs table
---@param depot_settings scripts.lib.domain.DepotSettings
function private.write_form(player, refs, depot_settings)
    refs.use_any_fuel_checkbox.state = depot_settings.use_any_fuel
end

---@param player LuaPlayer
---@return table
function private.create_for(player)
    local context = Context.from_player(player)
    local depot_settings = persistence_storage.get_depot_settings(context)
    local structure_config = {frame_name = FRAME.NAME, depot_settings = depot_settings}
    local refs = flib_gui.build(player.gui.screen, { structure.get(structure_config) })

    clean_train_station_dropdown_component = TrainStationSelector.new(
            player.surface,
            player.force,
            { on_selection_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form } },
            depot_settings and depot_settings.default_clean_station or nil,
            true
    )
    clean_train_station_dropdown_component:build(refs.clean_train_station_dropdown_wrapper)

    train_schedule_component = TrainScheduleSelector.new(
            context,
            private.handle_form_changed,
            depot_settings and depot_settings.default_destination_schedule or nil,
            true
    )
    train_schedule_component:build(refs.target_train_station_dropdown_wrapper)

    if depot_settings ~= nil then
        private.write_form(player, refs, depot_settings)
    end

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    storage.set(player, refs)

    return refs
end

---@param player LuaPlayer
function private.validate_form(player)
    local form_data = private.read_form(player)

    return flib_table.array_merge({
        clean_train_station_dropdown_component:validate_form(),
        train_schedule_component:validate_form(),
        validator.validate(private.validation_rules(), form_data)
    })
end

---@param player LuaPlayer
---@return table form data
function private.read_form(player)
    local refs = storage.refs(player)

    return {
        use_any_fuel = refs.use_any_fuel_checkbox.state,
        default_clean_station = clean_train_station_dropdown_component:read_form(),
        default_destination_schedule = train_schedule_component:read_form(),
        force_name = player.force.name,
        surface_name = player.surface.name,
    }
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

---@param event scripts.lib.decorator.Event
function public.dispatch(event)
    local handlers = {
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.open_frame),
            func = private.handle_open_frame
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.touch_form),
            func = private.handle_form_changed
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.close_frame),
            func = private.handle_frame_destroy
        },
        {
            match = event_dispatcher.match_target_and_action(FRAME.NAME, mod.defines.gui.actions.save_form),
            func = private.handle_save_form
        },
        {
            match = function()
                return train_schedule_component and event_dispatcher.match_target(train_schedule_component:name())
            end,
            func = function(e)
                if train_schedule_component == nil then
                    return false
                end

                return train_schedule_component:dispatch(e)
            end
        },
    }

    return event_dispatcher.dispatch(handlers, event,  FRAME.NAME)
end

return public