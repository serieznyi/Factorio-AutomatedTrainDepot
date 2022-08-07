local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local validator = require("scripts.gui.validator")
local Sequence = require("scripts.lib.Sequence")

local component_id_sequence = Sequence()

--- @class gui.component.ExtendedListBoxValue
--- @field caption table|string localized string or simple string
--- @field id uint identifier
--- @field tooltip table|string localized string or simple string
--- @field tags table

--- @module gui.component.ExtendedListBox
local ExtendedListBox = {
    ---@type uint
    id = nil,
    ---@type string
    name = nil,
    ---@type uint
    selected_id = nil,
    ---@type gui.component.ExtendedListBoxValue[]
    values = nil,
    ---@type table
    refs = {
        ---@type LuaGuiElement
        component = nil,
        ---@type LuaGuiElement
        container = nil,
    },
    ---@type bool
    required = false,
    ---@type function
    on_item_selected_closure = nil,
}

---@param values gui.component.ExtendedListBoxValue[]
---@param selected_id uint
---@param on_item_selected_closure function
---@param parent LuaGuiElement
---@return scripts.lib.domain.Train
function ExtendedListBox.new(parent, values, selected_id, required, on_item_selected_closure)
    ---@type gui.component.ExtendedListBox
    local self = {}
    setmetatable(self, { __index = ExtendedListBox })

    self.id = component_id_sequence:next()

    self.name = "extended_list_box_" .. self.id

    assert(values, "values is nil")
    self.values = values

    self.on_item_selected_closure = on_item_selected_closure

    if selected_id ~= nil then
        self.selected_id = selected_id
    end

    if required ~= nil then
        self.required = required
    else
        self:select_first()
    end

    self.refs = flib_gui.build(parent, { self:_structure() })

    self:refresh()

    self:_register_event_handlers()

    mod.log.debug("Component {1} created", {self.name}, self.name)

    return self
end

---@type string
function ExtendedListBox:read_form()
    return self:_get_value(self.refs)
end

---@return uint
function ExtendedListBox:get_selected_id()
    return self.selected_id
end

---@param id uint
function ExtendedListBox:remove_element(id)
    ---@param v gui.component.ExtendedListBoxValue
    local cleaned_data = flib_table.filter(self.values, function(v)
        return v.id ~= id
    end, true)

    self.values = cleaned_data
    self.selected_id = nil

    if #self.values > 0 then
        self:select_first()
    end
end

function ExtendedListBox:destroy()
    EventDispatcher.unregister_handlers_by_source(self.name)

    ---@param gui_element LuaGuiElement
    for _, gui_element in pairs(self.refs) do
        gui_element.destroy()
    end
end

function ExtendedListBox:validate_form()
    if self.required == false then
        return {}
    end

    return validator.validate(
            {
                {
                    match = validator.match_by_name({"value"}),
                    rules = { validator.check_empty },
                }
            },
            { value = self:_get_value(self.refs) }
    )
end

---@param new_values gui.component.ExtendedListBoxValue[]
function ExtendedListBox:refresh(new_values)
    if new_values ~= nil then
        self.values = new_values
    end

    ---@type LuaGuiElement
    local container = self.refs.container

    container.clear()

    ---@param value gui.component.ExtendedListBoxValue
    for i, value in ipairs(self.values) do
        local tags = value.tags or {}
        tags.id = value.id

        local selected = value.id == self.selected_id

        if self.selected_id == nil and i == 1 then
            selected = true
            self.selected_id = value.id
        end

        flib_gui.add(container, {
            type = "button",
            caption = value.caption,
            style = selected and "atd_button_list_box_item_active" or "atd_button_list_box_item",
            tooltip = value.tooltip,
            tags = tags,
            actions = {
                on_click = { event = mod.defines.events.on_gui_extended_list_box_item_selected }
            }
        })
    end
end

function ExtendedListBox:select_first()
    if #self.values > 0 then
        self.selected_id = self.values[1].id -- choose first
    end

end

function ExtendedListBox:_register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(mod.defines.events.on_gui_extended_list_box_item_selected),
            handler = function(e) return self:__handle_click(e) end
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, self.name)
    end
end

---@param event scripts.lib.event.Event
function ExtendedListBox:__handle_click(event)
    if self.refs == nil then
        return
    end

    self.selected_id = event:tags().id

    self:refresh()

    self:_after_choose_callback(event:tags())
end

function ExtendedListBox:_after_choose_callback(tags)
    if self.on_item_selected_closure then
        self.on_item_selected_closure(tags)
    end
end

function ExtendedListBox:_structure()
    return {
        type = "frame",
        style = "inside_deep_frame",
        ref = {"component"},
        children = {
            {
                type = "scroll-pane",
                ref = {"container"},
                horizontal_scroll_policy = "auto",
                vertical_scroll_policy = "always",
                style_mods = {
                    vertically_stretchable = true,
                    horizontally_stretchable = true,
                },
                style = "atd_scroll_pane_list_box",
            }
        }
    }
end

function ExtendedListBox:_get_value()
    return 1 -- todo fix me
end

return ExtendedListBox