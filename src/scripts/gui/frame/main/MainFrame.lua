local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.frame.main.structure")
local train_template_view_component = require("scripts.gui.frame.main.component.train_template_view.component")
local TrainsMap = require("scripts.gui.component.trains_map.TrainsMap")
local ExtendedListBox = require("scripts.gui.component.extended_list_box.component")
local mod_gui = require("scripts.util.gui")
local persistence_storage = require("scripts.persistence_storage")
local event_dispatcher = require("scripts.util.event_dispatcher")

--- @module gui.frame.MainFrame
local MainFrame = {
    ---@type string
    name = "main_frame",
    ---@type uint
    id = nil,
    ---@type gui.frame.Frame
    parent_frame = nil,
    ---@type int
    width = 1400,
    ---@type int
    height = 800,
    ---@type LuaPlayer
    player = nil,
    refs = {
        ---@type LuaGuiElement
        window = nil,
        ---@type LuaGuiElement
        titlebar_flow = nil,
        ---@type LuaGuiElement
        content_frame = nil,
        ---@type LuaGuiElement
        edit_button = nil,
        ---@type LuaGuiElement
        delete_button = nil,
    },
    components = {
        ---@type gui.component.ExtendedListBox
        trains_templates_list = nil,
        ---@type gui.component.TrainsMap
        trains_map = nil,
    },
}

---@param player LuaPlayer
function MainFrame.new(player)
    ---@type gui.frame.MainFrame
    local self = {}
    setmetatable(self, { __index = MainFrame,})

    self.player = player or nil
    assert(self.player, "player is nil")

    self:_initialize()

    mod.log.debug("Frame `{1}(id={2})` created", {self.name, self.id}, "gui")

    return self
end

---@type LuaGuiElement
function MainFrame:window()
    return self.refs.window
end

function MainFrame:update()
    local new_values = self:_get_trains_templates_values()

    self.components.trains_templates_list:refresh(new_values)

    self:_select_train_template_view(self.components.trains_templates_list.selected_id)

    self:_refresh_control_buttons()
end

function MainFrame:destroy()
    self.refs.window.visible = false

    ---@param component LuaGuiElement
    for _, component in pairs(self.components) do
        -- todo add abstraction or annotation fake
        component:destroy()
    end

    self.refs.window.destroy()

    mod.log.debug("Frame `{1}(id={2})` destroyed", {self.name, self.id}, "gui")
end

---@param event scripts.lib.decorator.Event
function MainFrame:dispatch(event)
    local handlers = {
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_delete_train_template_click),
            func = function(e) return self:_handle_delete_train_template(e) end,
            handler_source = self.name,
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_core_train_template_changed),
            func = function(e) return self:_handle_update(e) end,
            handler_source = self.name,
        },
        {
            match = event_dispatcher.match_event(mod.defines.events.on_gui_open_uncontrolled_trains_map_click),
            func = function(e) return self:_handle_open_uncontrolled_trains_map(e) end
        },
        {
            match = event_dispatcher.match_all(),
            func = train_template_view_component.dispatch
        },
        {
            match = event_dispatcher.match_all(),
            func = function(e) return self.components.trains_templates_list:dispatch(e) end
        },
    }

    return event_dispatcher.dispatch(handlers, event)
end

---@param event scripts.lib.decorator.Event
function MainFrame:_handle_open_uncontrolled_trains_map(event)
    local context = Context.from_player(self.player)
    local trains = persistence_storage.find_uncontrolled_trains(context)

    self.components.trains_map:update(trains)
end

function MainFrame:_refresh_control_buttons()
    local selected_train_template_id = self.components.trains_templates_list:get_selected_id()
    local train_template_selected = selected_train_template_id ~= nil

    self.refs.edit_button.enabled = train_template_selected
    self.refs.delete_button.enabled = train_template_selected

    if train_template_selected then
        -- todo сделать так же для delete
        flib_gui.update(self.refs.edit_button, { tags = { train_template_id = selected_train_template_id } })
    end
end

function MainFrame:_initialize()
    local structure_config = {frame_name = self.name, width = self.width, height = self.height}
    self.refs = flib_gui.build(self.player.gui.screen, { structure.get(structure_config) })
    self.id = self.refs.window.index

    self.components.trains_templates_list = ExtendedListBox.new(
            self.refs.trains_templates_list_container,
            self:_get_trains_templates_values(),
            nil,
            nil,
            function(tags) return self:update() end
    )

    self.components.trains_map = TrainsMap.new(
            self.player,
            self.refs.trains_map_view
    )

    self.refs.window.force_auto_center()
    self.refs.window.visible = true
    self.refs.titlebar_flow.drag_target = self.refs.window

    local resolution, scale = self.player.display_resolution, self.player.display_scale
    self.refs.window.location = {
        ((resolution.width - (self.width * scale)) / 2),
        ((resolution.height - (self.height * scale)) / 2)
    }

    self:update()
end

---@param event scripts.lib.decorator.Event
function MainFrame:_handle_delete_train_template(event)
    local train_template_id = self.components.trains_templates_list:get_selected_id()

    persistence_storage.delete_train_template(train_template_id)

    train_template_view_component.destroy()

    self.components.trains_templates_list:remove_element(train_template_id)

    self:update()

    return true
end

---@param event scripts.lib.decorator.Event
function MainFrame:_handle_update(event)
    self:update()

    return true
end

function MainFrame:_select_train_template_view(train_template_id)
    local train_template = persistence_storage.get_train_template(train_template_id)

    if train_template == nil then
        return
    end

    self.refs.trains_templates_view.clear()

    train_template_view_component.create(self.refs.trains_templates_view, self.player, train_template)
end

---@return gui.component.ExtendedListBoxValue
function MainFrame:_get_trains_templates_values()
    local context = Context.from_player(self.player)
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

return MainFrame