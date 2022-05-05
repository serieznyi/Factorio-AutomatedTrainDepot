local flib_table = require("__flib__.table")
local flib_gui = require("__flib__.gui")

local event_dispatcher = require("scripts.util.event_dispatcher")
local validator = require("scripts.gui.validator")
local Sequence = require("scripts.lib.Sequence")

local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

function private.build_structure()
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

---@param refs table
---@return string
function private.get_value(refs)
    return 1 -- todo fix me
end

local COMPONENT_NAME = "extended_list_box"

local component_id_sequence = Sequence()

---------------------------------------------------------------------------
-- -- -- TYPES
---------------------------------------------------------------------------

--- @class gui.component.ExtendedListBoxValue
--- @field caption table|string localized string or simple string
--- @field id uint identifier
--- @field tooltip table|string localized string or simple string
--- @field tags table
local lib_box_value = nil

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

--- @module gui.component.ExtendedListBox
local public = {
    ---@type uint
    selected_id = nil,
    ---@type gui.component.ExtendedListBoxValue[]
    values = nil,
    ---@type table
    refs = nil,
    ---@type bool
    required = false,
    ---@type uint
    component_id = nil,
    ---@type function
    on_item_selected_closure = nil,
}

---@param event scripts.lib.decorator.Event
function public:__handle_click(event)
    if self.refs == nil then
        return
    end

    local tags = flib_gui.get_tags(event.original_event.element)

    self.selected_id = tags.id

    self:refresh()

    if self.on_item_selected_closure then
        self.on_item_selected_closure(event, tags)
    end
end

---@type string
function public:read_form()
    return private.get_value(self.refs)
end

---@return uint
function public:get_selected_id()
    return self.selected_id
end

---@param id uint
function public:remove_element(id)
    ---@param v gui.component.ExtendedListBoxValue
    local cleaned_data = flib_table.filter(self.values, function(v)
        return v.id ~= id
    end)

    if #self.values > #cleaned_data then
        self.values = cleaned_data
        self.selected_id = nil

        if #self.values > 0 then
            self.selected_id = self.values[1].id
        end
    end
end

function public:validate_form()
    if self.required == false then
        return {}
    end

    return validator.validate(
            {
                {
                    match = validator.match_by_name({"value"}),
                    rules = { validator.rule_empty },
                }
            },
            { value = private.get_value(self.refs) }
    )
end

---@param new_values gui.component.ExtendedListBoxValue[]
function public:refresh(new_values)
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
                on_click = { target = self:name(), action = mod.defines.gui.actions.choose_list_box_item }
            }
        })
    end
end

---@param parent LuaGuiElement
function public:build(parent)
    self.refs = flib_gui.build(parent, { private.build_structure() })

    self:refresh()
end

function public:name()
    return COMPONENT_NAME .. "-" .. self.component_id
end

---@param values gui.component.ExtendedListBoxValue[]
---@param selected_id uint
---@param on_item_selected_closure function
---@return scripts.lib.domain.Train
function public.new(values, selected_id, required, on_item_selected_closure)
    ---@type gui.component.ExtendedListBox
    local self = {}
    setmetatable(self, { __index = public })

    self.component_id = component_id_sequence:next()

    assert(values, "values is nil")
    self.values = values

    if selected_id ~= nil then
        self.selected_id = selected_id
    end

    self.on_item_selected_closure = on_item_selected_closure

    if required ~= nil then
        self.required = required
    end

    mod.log.debug("Component created", {}, "gui.component.extended_list_box")

    return self
end

---@param event scripts.lib.decorator.Event
function public:dispatch(event)
    local event_handlers = {
        {
            match = event_dispatcher.match_target_and_action(self:name(), mod.defines.gui.actions.choose_list_box_item),
            func = function(e) return self:__handle_click(e) end
        },
    }

    -- todo add method for register handlers
    return event_dispatcher.dispatch(event_handlers, event, self:name())
end

return public