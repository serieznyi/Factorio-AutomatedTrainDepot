local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local constants = require("scripts.gui.frame.settings.constants")
local build_structure = require("scripts.gui.frame.settings.build_structure")
local validator = require("scripts.gui.validator")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local FRAME = constants.FRAME
local ACTION = constants.ACTION
local VALIDATION_RULES = {
    name = {
        function(value) return validator.rule_empty(value) end,
    },
    icon = {
        function(value) return validator.rule_empty(value) end,
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
    local form_data = frame.read_form(event)
    local validation_errors = frame.validate_form(event)

    frame.destroy(event)

    return true
end

local function get_surface_train_stations(player)
    local surface = player.surface
    local train_stations = game.get_train_stops({surface = surface})

    return flib_table.map(train_stations, function(el) return el.backer_name  end)
end

---@param player LuaPlayer
---@return table
local function create_for(player)
    local train_stations_list = flib_table.array_merge({
        {""},
        get_surface_train_stations(player),
    })

    local refs = flib_gui.build(player.gui.screen, { build_structure.get(train_stations_list) })

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
end

function frame.action_on_click()
    return {
        gui = FRAME.NAME,
        action = ACTION.OPEN
    }
end

---@return table
function frame.remote_interfaces()
    return {
        [mod.constants.remote_interfaces.settings_frame] = {}
    }
end

---@return string
function frame.name()
    return FRAME.NAME
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
        { gui = FRAME.NAME, action = ACTION.OPEN, func = function(_, e) return frame.open(e) end},
        { gui = FRAME.NAME, action = ACTION.CLOSE, func = function(_, e) return frame.destroy(e) end},
        { gui = FRAME.NAME, action = ACTION.SAVE, func = function(_, e) return save_form(e) end},
        { gui = FRAME.NAME, action = ACTION.FORM_CHANGED, func = function(_, e) return form_changed(e) end},
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