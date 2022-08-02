local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.frame.settings.structure")
local persistence_storage = require("scripts.persistence_storage")
local event_dispatcher = require("scripts.util.event_dispatcher")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.component")
local TrainScheduleSelector = require("scripts.gui.component.train_schedule_selector.component")
local validator = require("scripts.gui.validator")
local DepotSettings = require("scripts.lib.domain.DepotSettings")

--- @module gui.frame.SettingsFrame
local SettingsFrame = {
    ---@type string
    name = "settings_frame",
    ---@type LuaPlayer
    player = nil,
    ---@type gui.frame.Frame
    parent_frame = nil,
    refs = {
        ---@type LuaGuiElement
        window = nil,
        ---@type LuaGuiElement
        clean_train_station_dropdown_wrapper = nil,
        ---@type LuaGuiElement
        target_train_station_dropdown_wrapper = nil,
        ---@type LuaGuiElement
        use_any_fuel_checkbox = nil,
        ---@type LuaGuiElement
        titlebar_flow = nil,
        ---@type LuaGuiElement
        footerbar_flow = nil,
        ---@type LuaGuiElement
        submit_button = nil,
        ---@type LuaGuiElement
        validation_errors_container = nil,
    },
    components = {
        ---@type gui.component.TrainStationSelector
        clean_train_station_dropdown_component = nil,
        ---@type gui.component.TrainScheduleSelector
        train_schedule_component = nil,
    },
}

---@param player LuaPlayer
---@param parent_frame gui.frame.Frame
function SettingsFrame.new(parent_frame, player)
    ---@type gui.frame.SettingsFrame
    local self = {}
    setmetatable(self, { __index = SettingsFrame })

    self.player = player
    assert(self.player, "player is nil")

    self.parent_frame = parent_frame

    self:_initialize()

    mod.log.debug("Frame `{1}` created", {self.name}, "gui")

    return self
end

---@type LuaGuiElement
function SettingsFrame:window()
    return self.refs.window
end

function SettingsFrame:update()
end

function SettingsFrame:destroy()
    self.refs.window.visible = false

    ---@param component LuaGuiElement
    for _, component in pairs(self.components) do
        -- todo add abstraction or annotation fake
        component:destroy()
    end

    ---@param gui_element LuaGuiElement
    for _, gui_element in pairs(self.refs) do
        gui_element.destroy()
    end
end

function SettingsFrame:read_form()
    return {
        use_any_fuel = self.refs.use_any_fuel_checkbox.state,
        default_clean_station = self.components.clean_train_station_dropdown_component:read_form(),
        default_destination_schedule = self.components.train_schedule_component:read_form(),
        force_name = self.player.force.name,
        surface_name = self.player.surface.name,
    }
end

---@param event scripts.lib.decorator.Event
function SettingsFrame:dispatch(event)
    local handlers = {
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_settings_frame_changed),
            func = function(e) return self:_handle_form_changed(e) end,
            handler_source = self.name
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_settings_frame_save_click),
            func = function(e) return self:_handle_save_form(e) end,
            handler_source = self.name
        },
    }

    return event_dispatcher.dispatch(handlers, event)
end

---@param event scripts.lib.decorator.Event
function SettingsFrame:_handle_save_form(event)
    local form_data = self:read_form()
    local validation_errors = self:_validate_form()

    if #validation_errors == 0 then
        persistence_storage.set_depot_settings(DepotSettings.from_table(form_data))
    end

    script.raise_event(mod.defines.events.on_core_settings_changed, {
        player_index = event.player_index,
    })

    script.raise_event(mod.defines.events.on_gui_settings_frame_close_click, {
        player_index = event.player_index,
    })

    return true
end

---@param depot_settings scripts.lib.domain.DepotSettings
function SettingsFrame:_write_form(depot_settings)
    self.refs.use_any_fuel_checkbox.state = depot_settings.use_any_fuel
end

function SettingsFrame:_validation_rules()
    return {}
end

function SettingsFrame:_validate_form()
    local form_data = self:read_form(player)

    return flib_table.array_merge({
        self.components.clean_train_station_dropdown_component:validate_form(),
        self.components.train_schedule_component:validate_form(),
        validator.validate(self:_validation_rules(), form_data)
    })
end

---@param event scripts.lib.decorator.Event
function SettingsFrame:_handle_form_changed(event)
    self:_update_form()

    return true
end

function SettingsFrame:_update_form()
    local submit_button = self.refs.submit_button
    local validation_errors = self:_validate_form()

    submit_button.enabled = #validation_errors == 0
    validator.render_errors(self.refs.validation_errors_container, validation_errors)
end

function SettingsFrame:_initialize()
    local context = Context.from_player(self.player)
    local depot_settings = persistence_storage.get_depot_settings(context)
    local structure_config = {frame_name = self.name, depot_settings = depot_settings}
    self.refs = flib_gui.build(self.player.gui.screen, { structure.get(structure_config) })

    self.components.clean_train_station_dropdown_component = TrainStationSelector.new(
            self.player.surface,
            self.player.force,
            -- todo change it
            nil, --{ on_selection_state_changed = { target = self.name, action =  } },
            depot_settings and depot_settings.default_clean_station or nil,
            true
    )
    -- todo remove it
    self.components.clean_train_station_dropdown_component:build(self.refs.clean_train_station_dropdown_wrapper)

    self.components.train_schedule_component = TrainScheduleSelector.new(
            context,
            -- todo fix it
            nil, --private.handle_form_changed,
            depot_settings and depot_settings.default_destination_schedule or nil,
            true
    )
    -- todo remove it
    self.components.train_schedule_component:build(self.refs.target_train_station_dropdown_wrapper)

    if depot_settings ~= nil then
        self:_write_form(depot_settings)
    end

    self:_update_form()

    self.refs.window.force_auto_center()
    self.refs.window.visible = true
    self.refs.titlebar_flow.drag_target = self.refs.window
    self.refs.footerbar_flow.drag_target = self.refs.window
end

return SettingsFrame