local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local event_dispatcher = require("scripts.util.event_dispatcher")
local Context = require("scripts.lib.domain.Context")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.component")
local DepotSettings = require("scripts.lib.domain.DepotSettings")
local persistence_storage = require("scripts.persistence_storage")
local constants = require("scripts.gui.frame.settings.constants")
local build_structure = require("scripts.gui.frame.settings.build_structure")
local validator = require("scripts.gui.validator")

local FRAME = constants.FRAME
---@type gui.component.TrainStationSelector
local clean_train_station_dropdown_component
---@type gui.component.TrainStationSelector
local target_train_station_dropdown_component

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

---@param event EventData
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

---@param event EventData
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

---@param event EventData
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

---@param event EventData
function private.handle_frame_destroy(event)
    local player = game.get_player(event.player_index)

    private.destroy_frame(player)

    return true
end

---@param field_name string
---@param form table
function private.validation_not_same(field_name, form)
    local value1 = form["default_clean_station"]
    local value2 = form["default_destination_station"]

    if value1 ~= nil and value1 ~= "" and value1 == value2 then
        return {"validation-message.cant-be-equals", "default_clean_station", "default_destination_station"}
    end

    return nil
end

function private.validation_rules()
    return {
        {
            match = validator.match_by_name({"default_clean_station"}),
            rules = {
                private.validation_not_same
            },
        },
    }
end

function private.destroy_frame(player)
    local refs = storage.refs(player)

    if refs == nil then
        return
    end

    local window = refs.window

    window.visible = false
    window.destroy()

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
    local refs = flib_gui.build(player.gui.screen, { build_structure.get() })
    local context = Context.from_player(player)
    local depot_settings = persistence_storage.get_depot_settings(context)

    clean_train_station_dropdown_component = TrainStationSelector.new(
            player.surface,
            player.force,
            { on_selection_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form } },
            depot_settings and depot_settings.default_clean_station or nil,
            true
    )
    clean_train_station_dropdown_component:build(refs.clean_train_station_dropdown_wrapper)

    target_train_station_dropdown_component = TrainStationSelector.new(
            player.surface,
            player.force,
            { on_selection_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form }},
            depot_settings and depot_settings.default_destination_station or nil,
            true
    )
    target_train_station_dropdown_component:build(refs.target_train_station_dropdown_wrapper)

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
        target_train_station_dropdown_component:validate_form(),
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
        default_destination_station = target_train_station_dropdown_component:read_form(),
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

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local handlers = {
        { target = FRAME.NAME, action = mod.defines.gui.actions.open_frame,             func = private.handle_open_frame },
        { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form,             func = private.handle_form_changed },
        { target = FRAME.NAME, action = mod.defines.gui.actions.close_frame,            func = private.handle_frame_destroy },
        { target = FRAME.NAME, action = mod.defines.gui.actions.save_form,              func = private.handle_save_form },
    }

    return event_dispatcher.dispatch(handlers, event, action, FRAME.NAME)
end

return public