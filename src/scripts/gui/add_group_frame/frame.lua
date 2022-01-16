local flib_gui = require("__flib__.gui")

local train_part_chooser = require("train_part_chooser")
local validator = require("scripts.gui.validator")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local frame = {}

local FRAME_NAME = "add_group_frame"

local ACTION = {
    TRAIN_CHANGED = "train_changed",
    OPEN = "open",
    SAVE = "save",
    CLOSE = "close",
    FORM_CHANGED = "form_changed",
    DELETE_TRAIN_PART_CHOOSER = "delete_train_part_chooser",
    CHANGE_LOCOMOTIVE_DIRECTION = "change_locomotive_direction",
}

---@param event EventData
local function form_changed(event)
    local player = game.get_player(event.player_index)
    local gui = global.gui[FRAME_NAME][player.index]
    local validation_errors_container = gui.refs.validation_errors_container
    local submit_button = gui.refs.submit_button
    local validation_errors = frame.validate_form(event)

    mod_gui.clear_children(validation_errors_container)

    if #validation_errors == 0 then
        submit_button.enabled = true
    else
        submit_button.enabled = false

        for _, error in pairs(validation_errors) do
            validation_errors_container.add{type="label", caption=error}
        end
    end
end

local function save_form(event)
    local form_data = frame.read_form(event)
    local validation_errors = frame.validate_form(event)

    automated_train_depot.console.debug(automated_train_depot.table.to_string(form_data))
    automated_train_depot.console.debug(automated_train_depot.table.to_string(validation_errors))

    frame.destroy(event)
end

---@return table
local function gui_build_structure_frame()
    return {
        type = "frame",
        name = FRAME_NAME,
        direction = "vertical",
        ref  =  {"window"},
        style_mods = {
            minimal_width = 600,
            minimal_height = 400,
            vertically_stretchable = true,
            horizontally_stretchable = true,
        },
        children = {
            -- Titlebar
            {
                type = "flow",
                style = "flib_titlebar_flow",
                ref = {"titlebar_flow"},
                children = {
                    {
                        type = "label",
                        style = "frame_title",
                        caption = {"gui-name.automated-train-depot-add-group-frame"},
                        ignored_by_interaction = true
                    },
                    {
                        type = "empty-widget",
                        style = "flib_titlebar_drag_handle",
                        ignored_by_interaction = true
                    },
                }
            },
            -- Content
            {
                type = "frame",
                style = "inside_shallow_frame_with_padding",
                style_mods = {
                    horizontally_stretchable = true,
                    vertically_stretchable = true,
                },
                direction = "vertical",
                children = {
                    {
                        type = "table",
                        column_count = 2,
                        children = {
                            {
                                type = "label",
                                caption = "Group icon",
                            },
                            {
                                type = "choose-elem-button",
                                ref = {"group_icon_input"},
                                elem_type = "item",
                                actions = {
                                    on_elem_changed = { gui = FRAME_NAME, action = ACTION.FORM_CHANGED }
                                }
                            },
                            {
                                type = "label",
                                caption = "Group name",
                            },
                            {
                                type = "textfield",
                                ref = {"group_name_input"},
                                actions = {
                                    on_text_changed = { gui = FRAME_NAME, action = ACTION.FORM_CHANGED },
                                    on_confirmed = { gui = FRAME_NAME, action = ACTION.FORM_CHANGED },
                                }
                            },
                            {
                                type = "label",
                                caption = "Train",
                            },
                            {
                                type = "frame",
                                direction = "horizontal",
                                ref  =  {"train_building_container"},
                            }
                        }
                    },
                    {
                        type = "flow",
                        ref = {"validation_errors_container"},
                        direction = "vertical",
                    }
                }
            },
            -- Bottom control bar
            {
                type = "flow",
                style = "dialog_buttons_horizontal_flow",
                ref = {"footerbar_flow"},
                children = {
                    {
                        type = "button",
                        style = "back_button",
                        caption = "Cancel",
                        actions = {
                            on_click = { gui = FRAME_NAME, action = ACTION.CLOSE },
                        },
                    },
                    {
                        type = "empty-widget",
                        style = "flib_dialog_footer_drag_handle",
                        ignored_by_interaction = true
                    },
                    {
                        type = "button",
                        style = "confirm_button",
                        caption = "Create",
                        ref = {"submit_button"},
                        enabled = false,
                        actions = {
                            on_click = { gui = FRAME_NAME, action = ACTION.SAVE },
                        },
                    },
                }
            },
        }
    }
end

---@param player LuaPlayer
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    train_part_chooser.append_element_to(refs.train_building_container, player)

    global.gui[FRAME_NAME][player.index] = {
        refs = refs,
        state = {
            visible = false,
        },
    }
end

---@param player LuaPlayer
local function update_for(player)
    -- TODO
end

function frame.remote_interfaces()
    return {

    }
end

---@return string
function frame.name()
    return FRAME_NAME
end

function frame.init()
    global.gui[FRAME_NAME] = {}

    train_part_chooser.init()
end

---@param event EventData
function frame.open(event)
    local player = game.get_player(event.player_index)

    if global.gui[FRAME_NAME][player.index] == nil then
        create_for(player)
    else
        update_for(player)
    end

    local gui = global.gui[FRAME_NAME][player.index]

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    gui.state.visible = true
    player.opened = gui.refs.window
end

---@param event EventData
function frame.destroy(event)
    local player = game.get_player(event.player_index)
    local gui = global.gui[FRAME_NAME][player.index]

    if gui == nil then
        return
    end

    global.gui[FRAME_NAME][player.index] = nil

    local window = gui.refs.window

    window.visible = false
    window.destroy()

    train_part_chooser.destroy(player)
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME_NAME, action = ACTION.CLOSE, func = function(_, e) frame.destroy(e) end},
        { gui = FRAME_NAME, action = ACTION.OPEN, func = function(_, e) frame.open(e) end},
        { gui = FRAME_NAME, action = ACTION.SAVE, func = function(a, e) save_form(e) end},
        { gui = FRAME_NAME, action = ACTION.FORM_CHANGED, func = function(a, e) form_changed(e) end},
        { gui = train_part_chooser.name(), func = function(a, e) train_part_chooser.dispatch(a, e) end},
    }

    for _, h in ipairs(event_handlers) do
        if h.gui == action.gui and (h.action == action.action or h.action == nil) then
            if h.func(action, event) then
                processed = true
            end
        end
    end

    return processed
end

---@param event EventData
---@return table form data
function frame.read_form(event)
    local player = game.get_player(event.player_index)
    local gui = global.gui[FRAME_NAME][player.index]

    return {
        name = gui.refs.group_name_input.text or mod_table.NIL,
        icon = gui.refs.group_icon_input.elem_value or mod_table.NIL,
        train_color = {255, 255, 255}, -- TODO
        train =  train_part_chooser.read_form(event)
    }
end

function frame.validate_form(event)
    local form_data = frame.read_form(event)
    local rules = {
        name = {
            function(value) return validator.empty(value) end,
        },
        icon = {
            function(value) return validator.empty(value) end,
        }
    }

    local validation_errors = {}

    for form_field_name, form_value in pairs(form_data) do
        for field_name, field_validators in pairs(rules) do
            if form_field_name == field_name then
                for _, field_validator in pairs(field_validators) do
                    local error = field_validator({k = form_field_name, v = form_value})

                    if error ~= nil then
                        table.insert(validation_errors, error)
                    end
                end
            end
        end
    end

    return validation_errors
end

return frame