local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local logger = require("scripts.lib.logger")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_image = require("scripts.util.image")
local train_template_service = require("scripts.lib.train_template_service")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.component.train_template_view.structure")
local Sequence = require("scripts.lib.Sequence")
local TrainFormingTask = require("scripts.lib.domain.entity.task.TrainFormingTask")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")

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
        form_tasks_progress_container = nil,
        ---@type LuaGuiElement
        disband_tasks_progress_container = nil,
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

    logger.debug("Component {1} created", {self.name}, self.name)

    return self
end

function TrainTemplateView:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    if self.refs.train_template_container ~= nil then
        self.refs.train_template_container.destroy()
    end
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
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
            match = EventDispatcher.match_event(atd.defines.events.on_gui_train_template_enabled),
            handler = function(e) return self:_handle_enable_train_template(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_train_template_disabled),
            handler = function(e) return self:_handle_disable_train_template(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_trains_quantity_changed),
            handler = function(e) return self:_handle_change_trains_quantity(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return self:_handle_refresh_component(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = function(e) return self:_handle_refresh_component(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

function TrainTemplateView:_handle_enable_train_template(e)
    local train_template = train_template_service.enable_train_template(self.train_template_id)

    self:_refresh_component(train_template)

    return true
end

function TrainTemplateView:_handle_disable_train_template(e)
    local train_template = train_template_service.disable_train_template(self.train_template_id)

    self:_refresh_component(train_template)

    return true
end

function TrainTemplateView:_handle_change_trains_quantity(e)
    local count = self:_get_train_quantity_change_value(e)
    train_template_service.change_trains_quantity(self.train_template_id, count)

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

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainTemplateView:_train_template_component_caption(train_template)
    local icon = util_image.image_for_item(train_template.icon)

    return icon .. " " .. train_template.name
end

function TrainTemplateView:_refresh_component()
    local train_template = persistence_storage.find_train_template_by_id(self.train_template_id)

    -- update title

    self.refs.train_template_title_label.caption = self:_train_template_component_caption(train_template)

    -- update train parts view

    self.refs.train_view.clear()

    ---@param train_part scripts.lib.domain.entity.template.RollingStock
    for _, train_part in pairs(train_template.train) do
        flib_gui.add(self.refs.train_view, {
            type = "sprite-button",
            enabled = false,
            style = "flib_slot_default",
            sprite = util_image.image_path_for_item(train_part.prototype_name),
        })
    end

    -- update quantity input

    self.refs.trains_quantity.text = tostring(train_template.trains_quantity)

    -- update control buttons

    self.refs.enable_button.enabled = not train_template.enabled
    self.refs.disable_button.enabled = train_template.enabled

    -- update tasks view

    local context = Context.from_player(self.player)
    local tasks = persistence_storage.trains_tasks.find_all_tasks_for_template(context, train_template.id)

    self:_refresh_tasks(tasks)
end

---@param tasks scripts.lib.domain.entity.task.TrainDisbandTask[]|scripts.lib.domain.entity.task.TrainFormingTask[]
function TrainTemplateView:_refresh_tasks(tasks)
    self.refs.form_tasks_progress_container.clear()

    local form_tasks = flib_table.filter(tasks, function(t) return t.type == TrainFormingTask.type end, true)

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(form_tasks) do
        flib_gui.add(self.refs.form_tasks_progress_container, {
            type = "flow",
            direction = "vertical",
            children = {
                {
                    type="frame",
                    direction = "vertical",
                    style = "inside_shallow_frame_with_padding",
                    style_mods = {
                        vertically_squashable = true,
                        horizontally_squashable = true,
                    },
                    children = {
                        {
                            type = "label",
                            caption = {"train-template-view-component.atd-state", {"train-form-task-state.atd-" .. task.state}},
                        },
                        {
                            type = "progressbar",
                            value = task:progress() * 0.01,
                            style_mods = {
                                horizontally_stretchable = true,
                            },
                        }
                    }
                },
            },
        })
    end

    self.refs.disband_tasks_progress_container.clear()
    local disband_tasks = flib_table.filter(tasks, function(t) return t.type == TrainDisbandTask.type end, true)
    -- todo add
end

return TrainTemplateView