local flib_gui = require("__flib__.gui")

local validator = require("scripts.gui.validator")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local FRAME_NAME = automated_train_depot.constants.gui.frame_names.settings_frame

local ACTION = {
    OPEN = automated_train_depot.constants.gui.common_actions.open,
    CLOSE = automated_train_depot.constants.gui.common_actions.close,
    SAVE = automated_train_depot.constants.gui.common_actions.save,
    FORM_CHANGED = automated_train_depot.constants.gui.common_actions.form_changed,
}

local VALIDATION_RULES = {
    name = {
        function(value) return validator.empty(value) end,
    },
    icon = {
        function(value) return validator.empty(value) end,
    },
}

local persistence = {
    init = function()
        global.gui[FRAME_NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui[FRAME_NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_gui = function(player)
        return global.gui[FRAME_NAME][player.index]
    end,
    save_gui = function(player, refs)
        global.gui[FRAME_NAME][player.index] = {
            refs = refs,
        }
    end,
}

local frame = {}

---@param event EventData
local function form_changed(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)
    local validation_errors_container = gui.refs.validation_errors_container
    local submit_button = gui.refs.submit_button
    local validation_errors = frame.validate_form(event)

    mod_gui.clear_children(validation_errors_container)

    if #validation_errors == 0 then
        submit_button.enabled = true
    else
        submit_button.enabled = false

        for _, error in ipairs(validation_errors) do
            validation_errors_container.add{type="label", caption=error}
        end
    end

    return true
end

---@param event EventData
local function save_form(event)
    local form_data = frame.read_form(event)
    local validation_errors = frame.validate_form(event)

    frame.destroy(event)

    return true
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
                        caption = {"settings-frame.atd-title"},
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
                                caption = {"settings-frame.atd-use-any-supported-fuel"},
                                state = false,
                            },
                            {
                                type = "checkbox",
                                state = false,
                                actions = {
                                    on_elem_changed = { gui = FRAME_NAME, action = ACTION.FORM_CHANGED }
                                }
                            },
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
---@return table
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
end

---@param player LuaPlayer
---@return table
local function update_for(player)
    local gui = persistence.get_gui(player)

    -- TODO

    return gui
end

---@return table
function frame.remote_interfaces()
    return {

    }
end

---@return string
function frame.name()
    return FRAME_NAME
end

function frame.init()
    persistence.init()
end

function frame.load()
end

---@param event EventData
function frame.open(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    if gui == nil then
        gui = create_for(player)
    else
        gui = update_for(player)
    end

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    player.opened = gui.refs.window

    return true
end

---@param event EventData
function frame.destroy(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    if gui == nil then
        return
    end

    local window = gui.refs.window

    window.visible = false
    window.destroy()

    persistence.destroy(player)

    return true
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME_NAME, action = ACTION.OPEN, func = function(_, e) return frame.open(e) end},
        { gui = FRAME_NAME, action = ACTION.CLOSE, func = function(_, e) return frame.destroy(e) end},
        { gui = FRAME_NAME, action = ACTION.SAVE, func = function(_, e) return save_form(e) end},
        { gui = FRAME_NAME, action = ACTION.FORM_CHANGED, func = function(_, e) return form_changed(e) end},
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
    local gui = persistence.get_gui(player)

    return {
        use_any_fuel = mod_table.NIL,
        --icon = gui.refs.group_icon_input.elem_value or mod_table.NIL,
        --train_color = {255, 255, 255}, -- TODO
    }
end

function frame.validate_form(event)
    local form_data = frame.read_form(event)

    return validator.validate(VALIDATION_RULES, form_data)
end

return frame