local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local EventDispatcher = require("scripts.util.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.frame.settings.structure")
local persistence_storage = require("scripts.persistence_storage")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.TrainStationSelector")
local TrainScheduleSelector = require("scripts.gui.component.train_schedule_selector.TrainScheduleSelector")
local validator = require("scripts.gui.validator")
local DepotSettings = require("scripts.lib.domain.DepotSettings")

--- @module gui.frame.SettingsFrame
local SettingsFrame = {
    ---@type string
    name = nil,
    ---@type uint
    id = nil,
    ---@type LuaPlayer
    player = nil,
    ---@type gui.frame.Frame
    parent_frame = nil,
    refs = {
        ---@type LuaGuiElement
        window = nil,
        ---@type LuaGuiElement
        background_dimmer = nil,
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
function SettingsFrame:new(parent_frame, player)
    object = {}
    setmetatable(object, self)
    self.__index = self

    self.player = player
    assert(self.player, "player is nil")

    self.parent_frame = parent_frame

    local context = Context.from_player(self.player)
    local depot_settings = persistence_storage.get_depot_settings(context)
    local structure_config = {frame_name = self.name, depot_settings = depot_settings}
    self.refs = flib_gui.build(self.player.gui.screen, { structure.get(structure_config) })
    self.id = self.refs.window.index
    self.name = "settings_frame_" .. self.id

    self:_initialize(depot_settings)

    mod.log.debug("Frame {1} created", {self.name}, self.name)

    return object
end

---@type LuaGuiElement
function SettingsFrame:window()
    return self.refs.window
end

function SettingsFrame:bring_to_front()
    self.refs.window.bring_to_front()
end

function SettingsFrame:opened()
    self.player.opened = self.refs.window
end

function SettingsFrame:update()
end

function SettingsFrame:_create_dimmer()
    local resolution, scale = self.player.display_resolution, self.player.display_scale
    local dimmer_name = "background_dimmer_" .. self.name

    self.refs.background_dimmer = flib_gui.add(self.player.gui.screen, {
        type = "frame",
        name = dimmer_name,
        style = true and "atd_frame_semitransparent" or "atd_frame_transparent",
        actions = {
            on_click = { event = mod.defines.events.on_gui_background_dimmer_click, owner_name = self.name }
        },
        style_mods = {
            size = {
                math.floor(resolution.width / scale),
                math.floor(resolution.height / scale)
            }
        }
    })

    mod.log.debug("Frame {1} created", {dimmer_name}, self.name)
end

function SettingsFrame:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    self.refs.background_dimmer.visible = false
    self.refs.window.visible = false

    for _, component in pairs(self.components) do
        -- todo add abstraction or annotation fake
        component:destroy()
    end

    mod.log.debug("Frame {1} destroyed", {self.refs.background_dimmer.name}, self.name)
    self.refs.background_dimmer.destroy()
    self.refs.window.destroy()

    mod.log.debug("Frame {1} destroyed", {self.name}, self.name)
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

function SettingsFrame:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_settings_frame_changed),
            handler = function(e) return self:_handle_form_changed(e) end,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_settings_frame_save_click),
            handler = function(e) return self:_handle_save_form(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
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
        element = event.element,
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

---@param depot_settings scripts.lib.domain.DepotSettings
function SettingsFrame:_initialize(depot_settings)
    self:_register_event_handlers()

    self:_create_dimmer()

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
            Context.from_player(self.player),
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