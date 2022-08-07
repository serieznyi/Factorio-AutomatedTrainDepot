local flib_gui = require("__flib__.gui")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local mod_gui = require("scripts.util.gui")
local depot = require("scripts.depot.depot")
local persistence_storage = require("scripts.persistence_storage")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.component.train_template_view.structure")
local Sequence = require("scripts.lib.Sequence")

local component_id_sequence = Sequence()

---@module gui.component.TrainTemplateView
local TrainTemplateView = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    refs = {
        ---@type LuaGuiElement
        train_template_container = nil,
        ---@type LuaGuiElement
        train_template_title_label = nil,
        ---@type LuaGuiElement
        content = nil,
        ---@type LuaGuiElement
        train_view = nil,
        ---@type LuaGuiElement
        tasks_progress_container = nil,
        ---@type LuaGuiElement
        footerbar_flow = nil,
        ---@type LuaGuiElement
        trains_quantity = nil,
        ---@type LuaGuiElement
        disable_button = nil,
        ---@type LuaGuiElement
        enable_button = nil,
    },
    ---@type uint
    train_template_id = nil,
    ---@type LuaGuiElement
    container = nil,
}

---@param player LuaPlayer
---@param container LuaGuiElement
function TrainTemplateView.new(player, container)
    ---@type gui.component.TrainTemplateView
    local self = {}
    setmetatable(self, { __index = TrainTemplateView })

    self.id = component_id_sequence:next()

    self.name = "train_template_view_component_" .. self.id

    self.player = player or nil
    assert(self.player, "player is nil")

    self.container = container

    self:_register_event_handlers()

    mod.log.debug("Component {1} created", {self.name}, self.name)

    return self
end

function TrainTemplateView:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    if self.refs.train_template_container ~= nil then
        self.refs.train_template_container.destroy()
    end
end

---@param train_template scripts.lib.domain.TrainTemplate
function TrainTemplateView:update(train_template)
    if self.refs.train_template_container ~= nil then
        self.refs.train_template_container.destroy()
    end

    self.refs = flib_gui.build(self.container, { structure.get(train_template) })

    self.train_template_id = train_template.id

    self:_refresh_component()
end

function TrainTemplateView:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_train_template_enabled),
            handler = function(e) return self:_handle_enable_train_template(e) end,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_train_template_disabled),
            handler = function(e) return self:_handle_disable_train_template(e) end,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_trains_quantity_changed),
            handler = function(e) return self:_handle_change_trains_quantity(e) end,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_core_train_task_changed),
            handler = function(e) return self:_handle_refresh_component(e) end,
        },
        {
            match = EventDispatcher.match_event(mod.defines.events.on_core_train_template_changed),
            handler = function(e) return self:_handle_refresh_component(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

function TrainTemplateView:_handle_enable_train_template(e)
    local train_template = depot.enable_train_template(self.train_template_id)

    self:_refresh_component(train_template)

    return true
end

function TrainTemplateView:_handle_disable_train_template(e)
    local train_template = depot.disable_train_template(self.train_template_id)

    self:_refresh_component(train_template)

    return true
end

function TrainTemplateView:_handle_change_trains_quantity(e)
    local count = self:_get_train_quantity_change_value(e)
    depot.change_trains_quantity(self.train_template_id, count)

    self:_refresh_component()

    return true
end

function TrainTemplateView:_handle_refresh_component(e)
    self:_refresh_component()

    return true
end

---@param event scripts.lib.event.Event
---@return uint
function TrainTemplateView:_get_train_quantity_change_value(event)
    local action = event.action_data

    return event.action_data ~= nil and action.count or nil
end

---@param train_template scripts.lib.domain.TrainTemplate
function TrainTemplateView:_train_template_component_caption(train_template)
    local icon = mod_gui.image_for_item(train_template.icon)

    return icon .. " " .. train_template.name
end

function TrainTemplateView:_refresh_component()
    local train_template = persistence_storage.find_train_template_by_id(self.train_template_id)

    -- update title

    self.refs.train_template_title_label.caption = self:_train_template_component_caption(train_template)

    -- update train parts view

    self.refs.train_view.clear()

    ---@param train_part scripts.lib.domain.TrainPart
    for _, train_part in pairs(train_template.train) do
        flib_gui.add(self.refs.train_view, {
            type = "sprite-button",
            enabled = false,
            style = "flib_slot_default",
            sprite = mod_gui.image_path_for_item(train_part.prototype_name),
        })
    end

    -- update quantity input

    self.refs.trains_quantity.text = tostring(train_template.trains_quantity)

    -- update control buttons

    self.refs.enable_button.enabled = not train_template.enabled
    self.refs.disable_button.enabled = train_template.enabled

    -- update tasks view

    local context = Context.from_player(self.player)
    local tasks = persistence_storage.trains_tasks.find_forming_tasks(context, train_template.id)

    self.refs.tasks_progress_container.clear()

    ---@param task scripts.lib.domain.TrainFormingTask
    for _, task in ipairs(tasks) do
        flib_gui.add(self.refs.tasks_progress_container, {
            type = "progressbar",
            value = task:progress() * 0.01
        })
    end
end

return TrainTemplateView