local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local logger = require("scripts.lib.logger")
local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local structure = require("scripts.gui.frame.main.structure")
local TrainTemplateView = require("scripts.gui.component.train_template_view.TrainTemplateView")
local TrainsMap = require("scripts.gui.component.trains_map.TrainsMap")
local ExtendedListBox = require("scripts.gui.component.extended_list_box.ExtendedListBox")
local util_image = require("scripts.util.image")
local persistence_storage = require("scripts.persistence.persistence_storage")

--- @module gui.frame.MainFrame
local MainFrame = {
    ---@type string
    name = nil,
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
        background_dimmer = nil,
        ---@type LuaGuiElement
        titlebar_flow = nil,
        ---@type LuaGuiElement
        content_frame = nil,
        ---@type LuaGuiElement
        edit_button = nil,
        ---@type LuaGuiElement
        delete_button = nil,
        ---@type LuaGuiElement
        copy_button = nil,
        ---@type LuaGuiElement
        trains_templates_view_container = nil,
    },
    components = {
        ---@type gui.component.ExtendedListBox
        trains_templates_list = nil,
        ---@type gui.component.TrainsMap
        trains_map = nil,
        ---@type gui.component.TrainTemplateView
        trains_templates_view = nil,
    },
}

---@param player LuaPlayer
function MainFrame:new(player)
    object = {}
    setmetatable(object, self)
    self.__index = self

    self.player = assert(player, "player is nil")

    local structure_config = {frame_name = self.name, width = self.width, height = self.height}
    self.refs = flib_gui.build(self.player.gui.screen, { structure.get(structure_config) })
    self.id = self.refs.window.index
    self.name = "main_frame_" .. self.id

    self:_initialize()

    logger.debug("Frame {1} created", {self.name}, self.name)

    return object
end

function MainFrame:bring_to_front()
    self.refs.background_dimmer.bring_to_front()
    self.refs.window.bring_to_front()
end

function MainFrame:_create_dimmer()
    local resolution, scale = self.player.display_resolution, self.player.display_scale
    local dimmer_name = "background_dimmer_" .. self.name

    self.refs.background_dimmer = flib_gui.add(self.player.gui.screen, {
        type = "frame",
        name = dimmer_name,
        style = false and "atd_frame_semitransparent" or "atd_frame_transparent",
        actions = {
            on_click = { event = atd.defines.events.on_gui_background_dimmer_click, owner_name = self.name }
        },
        style_mods = {
            size = {
                math.floor(resolution.width / scale),
                math.floor(resolution.height / scale)
            }
        }
    })

    logger.debug("Frame {1} created", {dimmer_name}, self.name)
end

function MainFrame:opened()
    self.player.opened = self.refs.window
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
    EventDispatcher.unregister_handlers_by_source(self.name)

    self.refs.background_dimmer.visible = false
    self.refs.window.visible = false

    for _, component in pairs(self.components) do
        -- todo add abstraction or annotation fake
        component:destroy()
    end

    logger.debug("Frame {1} destroyed", {self.refs.background_dimmer.name}, self.name)
    self.refs.background_dimmer.destroy()
    self.refs.window.destroy()

    logger.debug("Frame {1} destroyed", {self.name}, "gui")
end

---@param event scripts.lib.event.Event
function MainFrame:_handle_open_uncontrolled_trains_map(event)
    local context = Context.from_player(self.player)
    local trains = persistence_storage.find_uncontrolled_trains(context)

    self.components.trains_map:update(trains)
end

---@param event scripts.lib.event.Event
function MainFrame:_handle_copy_train_template(event)
    local train_template_id = self.components.trains_templates_list:get_selected_id()
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    persistence_storage.add_train_template(train_template:clone())

    self:update()

    return true
end

function MainFrame:_refresh_control_buttons()
    local selected_train_template_id = self.components.trains_templates_list:get_selected_id()
    local train_template_selected = selected_train_template_id ~= nil

    self.refs.edit_button.enabled = train_template_selected
    self.refs.delete_button.enabled = train_template_selected
    self.refs.copy_button.enabled = train_template_selected

    if train_template_selected then
        -- todo сделать так же для delete
        flib_gui.update(self.refs.edit_button, { tags = { train_template_id = selected_train_template_id } })
    end
end

function MainFrame:_initialize()
    self:_register_event_handlers()

    self:_create_dimmer()

    self.components.trains_templates_view = TrainTemplateView.new(
            self.player,
            self.refs.trains_templates_view_container
    )

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

---@param event scripts.lib.event.Event
function MainFrame:_handle_delete_train_template(event)
    local train_template_id = self.components.trains_templates_list:get_selected_id()

    persistence_storage.delete_train_template(train_template_id)

    self.components.trains_templates_view:destroy()

    self.components.trains_templates_list:remove_element(train_template_id)

    self:update()

    return true
end

---@param event scripts.lib.event.Event
function MainFrame:_handle_update(event)
    self:update()

    return true
end

function MainFrame:_select_train_template_view(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    if train_template == nil then
        return
    end

    self.components.trains_templates_view:update(train_template)
end

---@param str string
---@return string
function MainFrame:_extract_paths(str)
    local extract_vars = {}
    local cleaned_string = ""
    local init = 1

    while (true) do
        local start, stop = string.find(str, "%[[%w_-]+%=[[%w_-]+%]", init)

        if start == nil and stop == nil then
            cleaned_string = cleaned_string .. string.sub(str, init)
            break
        end

        table.insert(extract_vars, string.sub(str, start, stop))

        cleaned_string = cleaned_string .. string.sub(str, init, start - 1) .. "{" .. #extract_vars .. "}"

        init = stop + 1
    end

    return cleaned_string, extract_vars
end

---@param str string
---@return string
function MainFrame:_insert_paths(str, vars)
    for i, var in ipairs(vars) do
        str = string.gsub(str, "(%{" .. i .. "%})", var)
    end

    return str
end

--- Pads str to length len with char from right
function MainFrame:_lpad(str, len, char)
    if char == nil then char = ' ' end

    return str .. string.rep(char, len - #str)
end

---@return gui.component.ExtendedListBoxValue
function MainFrame:_get_trains_templates_values()
    local context = Context.from_player(self.player)
    local trains_templates = persistence_storage.find_train_templates_by_context(context)

    ---@param t scripts.lib.domain.entity.template.TrainTemplate
    return flib_table.map(
            trains_templates,
            function(t)
                local icon = util_image.image_for_item(t.icon)

                return {
                    caption = icon .. " " .. t.name,
                    id = t.id,
                    tooltip = { "main-frame.atd-train-template-list-button-tooltip", t.name},
                }
            end
    )
end

function MainFrame:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_delete_train_template_click),
            handler = function(e) return self:_handle_delete_train_template(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = function(e) return self:_handle_update(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_open_uncontrolled_trains_map_click),
            handler = function(e) return self:_handle_open_uncontrolled_trains_map(e) end
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_gui_copy_train_template_click),
            handler = function(e) return self:_handle_copy_train_template(e) end
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end

end

return MainFrame