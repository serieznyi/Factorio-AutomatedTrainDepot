local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local constants = require("scripts.gui.frame.add_group.constants")
local build_structure = require("scripts.gui.frame.add_group.build_structure")
local train_builder_component = require("scripts.gui.frame.add_group.component.train_builder.component")
local validator = require("scripts.gui.validator")
local storage = require("scripts.storage")

local FRAME = constants.FRAME
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
        global.gui[FRAME.NAME] = {}
    end,
    ---@param player LuaPlayer
    destroy = function(player)
        global.gui[FRAME.NAME][player.index] = nil
    end,
    ---@param player LuaPlayer
    ---@return table
    get_gui = function(player)
        return global.gui[FRAME.NAME][player.index]
    end,
    save_gui = function(player, refs)
        global.gui[FRAME.NAME][player.index] = {
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
    local player = game.get_player(event.player_index)
    local form_data = frame.read_form(event)
    local validation_errors = frame.validate_form(event)

    if #validation_errors == 0 then
        storage.add_group(player, form_data)
    end

    frame.close(event)

    script.raise_event(mod.defines.events.on_group_saved, {player_index = event.player_index})

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


function frame.action_on_click()
    return {
        gui = FRAME.NAME,
        action = ACTION.OPEN
    }
end

---@return string
function frame.name()
    return FRAME.NAME
end

function frame.init()
    persistence.init()
    train_builder_component.init()
end

function frame.load()
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
function frame.dispatch(event, action)
    local handlers = {
        { gui = FRAME.NAME, action = ACTION.CLOSE, func = frame.close},
        { gui = FRAME.NAME, action = ACTION.OPEN, func = frame.open},
        { gui = FRAME.NAME, action = ACTION.SAVE, func = save_form},
        { gui = FRAME.NAME, action = ACTION.FORM_CHANGED, func = form_changed},
        { gui = train_builder_component.name(), func = train_builder_component.dispatch},
        { event = mod.defines.events.on_form_changed, func = form_changed },
    }

    return mod_event.dispatch(handlers, event, action)
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