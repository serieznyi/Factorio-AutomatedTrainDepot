local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local constants = require("scripts.gui.frame.add_group_frame.constants")
local build_structure = require("scripts.gui.frame.add_group_frame.build_structure")
local train_builder_component = require("scripts.gui.frame.add_group_frame.component.train_builder")
local validator = require("scripts.gui.validator")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local FRAME_NAME = constants.FRAME_NAME

local ACTION = constants.ACTION

local VALIDATION_RULES = {
    {
        match = validator.match_by_name("name"),
        rules = { validator.rule_empty },
    },
    {
        match = validator.match_by_name("icon"),
        rules = { validator.rule_empty },
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

local on_form_save_callback = function()  end

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
    local player = game.get_player(event.player_index)
    local form_data = frame.read_form(event)
    local validation_errors = frame.validate_form(event)

    if #validation_errors == 0 then
        on_form_save_callback(player, form_data)
    end

    frame.close(event)

    remote.call("automated_train_depot.main_frame", "update", player)

    return true
end

---@param player LuaPlayer
---@return table
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, {build_structure.get()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    train_builder_component.append_component(refs.train_builder_container, player)

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
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
    train_builder_component.init()
    train_builder_component.on_form_changed(function(e) form_changed(e) end)
end

function frame.load()
    train_builder_component.on_form_changed(function(e) form_changed(e) end)
end

---@param callback function
function frame.on_form_save(callback)
    on_form_save_callback = callback
end

---@param event EventData
function frame.open(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    if gui == nil then
        gui = create_for(player)
    end

    gui.refs.window.bring_to_front()
    gui.refs.window.visible = true
    player.opened = gui.refs.window

    return true
end

---@param event EventData
function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    if gui == nil then
        return
    end

    local window = gui.refs.window

    window.visible = false
    window.destroy()

    persistence.destroy(player)

    train_builder_component.destroy(player)

    return true
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME_NAME, action = ACTION.CLOSE, func = function(_, e) return frame.close(e) end},
        { gui = FRAME_NAME, action = ACTION.OPEN, func = function(_, e) return frame.open(e) end},
        { gui = FRAME_NAME, action = ACTION.SAVE, func = function(_, e) return save_form(e) end},
        { gui = FRAME_NAME, action = ACTION.FORM_CHANGED, func = function(_, e) return form_changed(e) end},
        { gui = train_builder_component.name(), func = function(a, e) return train_builder_component.dispatch(a, e) end},
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
        name = gui.refs.group_name_input.text or mod_table.NIL,
        icon = gui.refs.group_icon_input.elem_value or mod_table.NIL,
        train_color = {255, 255, 255}, -- TODO add chooser
        train =  train_builder_component.read_form(event)
    }
end

function frame.validate_form(event)
    local form_data = frame.read_form(event)

    return flib_table.array_merge({
        train_builder_component.validate_form(event),
        validator.validate(VALIDATION_RULES, form_data)
    })
end

return frame