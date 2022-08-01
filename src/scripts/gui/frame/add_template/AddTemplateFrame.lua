local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local TrainTemplate = require("scripts.lib.domain.TrainTemplate")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.frame.add_template.structure")
local persistence_storage = require("scripts.persistence_storage")
local event_dispatcher = require("scripts.util.event_dispatcher")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.component")
local TrainScheduleSelector = require("scripts.gui.component.train_schedule_selector.component")
local train_builder_component = require("scripts.gui.frame.add_template.component.train_builder.component")
local validator = require("scripts.gui.validator")

local function validation_rules()
    return {
        {
            match = validator.match_by_name({"name"}),
            rules = { validator.rule_empty },
        },
        {
            match = validator.match_by_name({"icon"}),
            rules = { validator.rule_empty },
        },
    }
end

--- @module gui.frame.AddTemplateFrame
local AddTemplateFrame = {
    ---@type string
    name = "add_template_frame",
    ---@type LuaPlayer
    player = nil,
    ---@type uint
    train_template_id = nil,
    refs = {
        ---@type LuaGuiElement
        window = nil,
        ---@type LuaGuiElement
        titlebar_flow = nil,
        ---@type LuaGuiElement
        destination_schedule_dropdown_wrapper = nil,
        ---@type LuaGuiElement
        footerbar_flow = nil,
        ---@type LuaGuiElement
        train_builder_container = nil,
        ---@type LuaGuiElement
        icon_input = nil,
        ---@type LuaGuiElement
        name_input = nil,
    },
    components = {
        ---@type gui.component.TrainStationSelector
        clean_train_station_dropdown = nil,
        ---@type gui.component.TrainScheduleSelector
        destination_train_schedule_dropdown = nil,
    },
}

---@param player LuaPlayer
function AddTemplateFrame.new(player, train_template_id)
    ---@type gui.frame.AddTemplateFrame
    local self = {}
    setmetatable(self, { __index = AddTemplateFrame })

    self.player = player or nil
    assert(self.player, "player is nil")

    self.train_template_id = train_template_id or nil

    self:_initialize()

    mod.log.debug("Frame `{1}` created", {self.name}, "gui")

    return self
end

function AddTemplateFrame:show()
    self.refs.window.bring_to_front()
    self.refs.window.visible = true
    self.player.opened = self.refs.window

    mod.util.gui.frame_stack_push(self.refs.window)
end

function AddTemplateFrame:update()
end

function AddTemplateFrame:destroy()
    self.refs.window.visible = false

    if self.player.opened == self.refs.window then
        self.player.opened = nil
    end

    mod.util.gui.frame_stack_pop(self.refs.window)

    ---@param component LuaGuiElement
    for _, component in pairs(self.components) do
        -- todo add abstraction or annotation fake
        component:destroy()
    end

    ---@param gui_element LuaGuiElement
    for _, gui_element in pairs(self.refs) do
        gui_element.destroy()
    end

    -- todo make dynamic
    train_builder_component.destroy()
end

---@return scripts.lib.domain.TrainTemplate form data
function AddTemplateFrame:read_form()
    local window_tags = flib_gui.get_tags(self.refs.window)
    local context = Context.from_player(self.player)
    ---@type scripts.lib.domain.TrainTemplate
    local train_template = TrainTemplate.from_context(window_tags.train_template_id, context)

    train_template.name = self.refs.name_input.text or mod.util.table.NIL
    train_template.icon = self.refs.icon_input.elem_value or mod.util.table.NIL
    -- TODO add chooser
    train_template.train_color = { 255, 255, 255}
    train_template.train =  train_builder_component.read_form(self.player)
    train_template.enabled = false
    train_template.clean_station = self.components.clean_train_station_dropdown:read_form()
    train_template.destination_station = self.components.destination_train_schedule_dropdown:read_form()
    train_template.trains_quantity = 0

    return train_template
end

---@param event scripts.lib.decorator.Event
function AddTemplateFrame:dispatch(event)
    local handlers = {
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_adding_template_frame_changed),
            func = function(e) return self:_handle_form_changed(e) end,
            handler_source = self.name
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_save_adding_template_frame_click),
            func = function(e) return self:_handle_save_form(e) end,
            handler_source = self.name
        },
        {
            match = event_dispatcher.match_all(),
            func = train_builder_component.dispatch,
            handler_source = self.name
        },
    }

    return event_dispatcher.dispatch(handlers, event)
end

---@param event scripts.lib.decorator.Event
function AddTemplateFrame:_handle_save_form(event)
    local form_data = self:read_form()
    local validation_errors = self:_validate_form()

    if #validation_errors == 0 then
        local train_template = persistence_storage.add_train_template(form_data)

        script.raise_event(mod.defines.events.on_core_train_template_changed, {
            player_index = event.player_index,
            train_template_id = train_template.id
        })

        script.raise_event(mod.defines.events.on_gui_close_add_template_frame_click, {
            player_index = event.player_index,
        })
    end

    return true
end

---@param train_template scripts.lib.domain.TrainTemplate
function AddTemplateFrame:_write_form(train_template)
    self.refs.icon_input.elem_value = train_template.icon
    self.refs.name_input.text = train_template.name

    -- todo remove key from parts
    for _, train_part in pairs(train_template.train) do
        train_builder_component.add_train_part(self.refs.train_builder_container, self.player, train_part)
    end

end

function AddTemplateFrame:_validate_form()
    local form_data = self:read_form()

    return flib_table.array_merge({
        train_builder_component.validate_form(self.player),
        self.components.clean_train_station_dropdown:validate_form(),
        self.components.destination_train_schedule_dropdown:validate_form(),
        validator.validate(validation_rules(), form_data)
    })
end

---@param event scripts.lib.decorator.Event
function AddTemplateFrame:_handle_form_changed(event)
    local submit_button = self.refs.submit_button
    local validation_errors = self:_validate_form()

    validator.render_errors(self.refs.validation_errors_container, validation_errors)

    submit_button.enabled = #validation_errors == 0

    return true
end

function AddTemplateFrame:_initialize()
    local context = Context.from_player(self.player)
    local train_template = persistence_storage.get_train_template(self.train_template_id)
    local structure_config = {frame_name = self.name, train_template = train_template}
    local depot_settings = persistence_storage.get_depot_settings(context)
    self.refs = flib_gui.build(self.player.gui.screen, { structure.get(structure_config) })

    self.components.clean_train_station_dropdown = TrainStationSelector.new(
            self.player.surface,
            self.player.force,
            -- todo fix it
            null, --{ on_selection_state_changed = { target = self.name, action =  } },
            train_template and train_template.clean_station or (depot_settings and depot_settings.default_clean_station or nil),
            true
    )
    self.components.clean_train_station_dropdown:build(self.refs.clean_train_station_dropdown_wrapper)


    self.components.destination_train_schedule_dropdown = TrainScheduleSelector.new(
            context,
            function(e) return self:_handle_form_changed(e) end,
            train_template and train_template.destination_schedule or (depot_settings and depot_settings.default_destination_schedule or nil),
            true
    )
    self.components.destination_train_schedule_dropdown:build(self.refs.destination_schedule_dropdown_wrapper)

    self.refs.window.force_auto_center()
    self.refs.titlebar_flow.drag_target = self.refs.window
    self.refs.footerbar_flow.drag_target = self.refs.window

    train_builder_component.load()
    train_builder_component.on_changed(function(e) return self:_handle_form_changed(e) end)
    train_builder_component.add_train_part(self.refs.train_builder_container, self.player)

    if train_template ~= nil then
        self:_write_form(train_template)
    end
end

return AddTemplateFrame