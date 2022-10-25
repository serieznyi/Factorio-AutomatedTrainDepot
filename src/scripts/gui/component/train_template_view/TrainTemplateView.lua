local flib_gui = require("__flib__.gui")

local logger = require("scripts.lib.logger")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local util_image = require("scripts.util.image")
local train_template_service = require("scripts.lib.train_template_service")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.component.train_template_view.structure")
local Sequence = require("scripts.lib.Sequence")
local TrainFormingTask = require("scripts.lib.domain.entity.task.TrainFormingTask")

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
        ---@type LuaGuiElement
        tasks_info_block = nil,
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

    self.player = assert(player, "player is nil")

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
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_deleted),
            handler = function(e) return self:_handle_refresh_component(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_added),
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
    train_template_service.enable_train_template(self.train_template_id)

    self:_refresh_component()

    return true
end

function TrainTemplateView:_handle_disable_train_template(e)
    train_template_service.disable_train_template(self.train_template_id)

    self:_refresh_component()

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

    self:_refresh_tasks()

    self:_refresh_info_block()
end

function TrainTemplateView:_refresh_tasks()
    local context = Context.from_player(self.player)

    self.refs.form_tasks_progress_container.clear()
    local form_tasks = persistence_storage.trains_tasks.find_forming_tasks(context, self.train_template_id)
    local planned_amount_form_tasks = train_template_service.planned_quantity_form_tasks(self.train_template_id)

    ---@param task scripts.lib.domain.entity.task.TrainFormingTask
    for _, task in pairs(form_tasks) do
        flib_gui.add(self.refs.form_tasks_progress_container, self:_build_task_block(task))
    end

    if planned_amount_form_tasks > 0 then
        flib_gui.add(self.refs.form_tasks_progress_container, self:_build_future_tasks_block(planned_amount_form_tasks))
    end

    self.refs.disband_tasks_progress_container.clear()
    local disband_tasks = persistence_storage.trains_tasks.find_disbanding_tasks(context, self.train_template_id)
    local planned_amount_disband_tasks = train_template_service.planned_quantity_disband_tasks(self.train_template_id)

    ---@param task scripts.lib.domain.entity.task.TrainDisbandTask
    for _, task in pairs(disband_tasks) do
        flib_gui.add(self.refs.disband_tasks_progress_container, self:_build_task_block(task))
    end

    if planned_amount_disband_tasks > 0 then
        flib_gui.add(self.refs.disband_tasks_progress_container, self:_build_future_tasks_block(planned_amount_disband_tasks))
    end
end

function TrainTemplateView:_refresh_info_block()
    local context = Context.from_player(self.player)
    local train_template = persistence_storage.find_train_template_by_id(self.train_template_id)
    local real_trains_quantity = #persistence_storage.find_controlled_trains_for_template(context, self.train_template_id)
    local potential_trains_quantity = train_template.trains_quantity

    self.refs.tasks_info_block.clear()

    flib_gui.add(self.refs.tasks_info_block, {
        type = "label",
        caption = { "train-template-view-component-info-block.atd-potential-trains-quantity", potential_trains_quantity },
        style_mods = {
            font_color = {255, 255, 0}
        },
    })

    flib_gui.add(self.refs.tasks_info_block, {
        type = "label",
        caption = { "train-template-view-component-info-block.atd-real-trains-quantity", real_trains_quantity },
        style_mods = {
            font_color = {255, 0, 255}
        },
    })
end

---@param amount uint
---@return table
function TrainTemplateView:_build_future_tasks_block(amount)
    return {
        type = "frame",
        direction = "vertical",
        style_mods = {
            bottom_padding = 5,
        },
        children = {
            {
                type="flow",
                direction = "vertical",
                style_mods = {
                    vertically_squashable = true,
                    horizontally_stretchable = true,
                },
                children = {
                    {
                        type = "label",
                        caption = {"train-template-view-component.atd-state", {"train-template-view-component.atd-wait"}},
                    },
                    {
                        type = "label",
                        caption = amount,
                    },
                }
            },
        },
    }
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask|scripts.lib.domain.entity.task.TrainFormingTask
---@return table
function TrainTemplateView:_build_task_block(task)
    local state_text = nil

    if task.type == TrainFormingTask.type then
        state_text = {"train-form-task-state.atd-" .. task.state}
    else
        state_text = {"train-disband-task-state.atd-" .. task.state}
    end

    return {
        type = "frame",
        direction = "vertical",
        style_mods = {
            bottom_padding = 5,
        },
        children = {
            {
                type="flow",
                direction = "vertical",
                style_mods = {
                    vertically_squashable = true,
                    horizontally_stretchable = true,
                },
                children = {
                    {
                        type = "label",
                        caption = {"train-template-view-component.atd-state", state_text},
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
    }
end

return TrainTemplateView