local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")
local mod_table = require("scripts.util.table")
local mod_gui = require("scripts.util.gui")

local constants = require("scripts.gui.frame.add_template.constants")
local build_structure = require("scripts.gui.frame.add_template.build_structure")
local train_builder_component = require("scripts.gui.frame.add_template.component.train_builder.component")
local validator = require("scripts.gui.validator")
local persistence_storage = require("scripts.persistence_storage")

local FRAME = constants.FRAME
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

local public = {}
local private = {}
local storage = {}

---------------------------------------------------------------------------
-- -- -- STORAGE
---------------------------------------------------------------------------

function storage.init()
    global.gui.frame[FRAME.NAME] = {}
end

---@param player LuaPlayer
function storage.clean(player)
    global.gui.frame[FRAME.NAME][player.index] = nil
end

---@param player LuaPlayer
---@return table
function storage.refs(player)
    if global.gui.frame[FRAME.NAME][player.index] == nil then
        return nil
    end

    return global.gui.frame[FRAME.NAME][player.index].refs
end

---@param player LuaPlayer
---@param refs table
function storage.set(player, refs)
    global.gui.frame[FRAME.NAME][player.index] = {
        refs = refs,
    }
end

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param event EventData
function private.handle_frame_open(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local tags = flib_gui.get_tags(event.element)

    if refs == nil then
        refs = private.create_for(player, tags.train_template_id)
    end

    refs.window.bring_to_front()
    refs.window.visible = true
    player.opened = refs.window

    return true
end

---@param event EventData
function private.handle_frame_close(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)

    if refs == nil then
        return
    end

    local window = refs.window

    window.visible = false
    window.destroy()

    storage.clean(player)

    train_builder_component.destroy(player)

    return true
end

---@param event EventData
function private.handle_trigger_form_changed(event)
    script.raise_event(
            mod.defines.events.on_gui_form_changed_mod,
            { target = FRAME.NAME,  player_index = event.player_index}
    )

    return true
end

---@param event EventData
function private.handle_form_changed(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local validation_errors_container = refs.validation_errors_container
    local submit_button = refs.submit_button
    local validation_errors = public.validate_form(event)

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
function private.handle_save_form(event)
    local player = game.get_player(event.player_index)
    local form_data = public.read_form(event)
    local validation_errors = public.validate_form(event)

    if #validation_errors == 0 then
        local train_template = persistence_storage.add_train_template(player, form_data)

        script.raise_event(
                mod.defines.events.on_train_template_saved_mod,
                {
                    player_index = event.player_index,
                    target = mod.defines.gui.frames.main.name,
                    train_template_id = train_template.id
                }
        )
    end

    private.handle_frame_close(event)

    return true
end

---@param player LuaPlayer
---@param train_template atd.TrainTemplate
function private.write_form(player, refs, train_template)

    refs.icon_input.elem_value = train_template.icon
    refs.name_input.text = train_template.name

    -- todo remove key from parts
    for _, train_part in pairs(train_template.train) do
        train_builder_component.add_train_part(refs.train_builder_container, player, train_part)
    end

end

---@param player LuaPlayer
---@param train_template_id uint
---@return table
function private.create_for(player, train_template_id)
    local train_template = persistence_storage.get_train_template(player, train_template_id)

    local refs = flib_gui.build(player.gui.screen, {build_structure.get(train_template)})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window
    refs.footerbar_flow.drag_target = refs.window

    if train_template_id ~= nil then
        private.write_form(player, refs, train_template)
    end

    train_builder_component.add_train_part(refs.train_builder_container, player)

    storage.set(player, refs)

    return refs
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@return string
function public.name()
    return FRAME.NAME
end

function public.init()
    storage.init()
    train_builder_component.init()
end

function public.load()
    train_builder_component.load()
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local handlers = {
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.trigger_form_changed,  func = private.handle_trigger_form_changed },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.close_frame,           func = private.handle_frame_close },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.open_frame,            func = private.handle_frame_open },
        { target = FRAME.NAME, action = mod.defines.gui.actions.edit_train_template, func = private.handle_frame_open },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.save_form,             func = private.handle_save_form },
        { target = train_builder_component.name(),  action = mod.defines.gui.actions.any,                   func = train_builder_component.dispatch},
        -- todo
        { target = FRAME.NAME, event = mod.defines.events.on_gui_form_changed_mod, func = private.handle_form_changed },
    }

    return mod_event.dispatch(handlers, event, action, FRAME.NAME)
end

---@param event EventData
---@return atd.TrainTemplate form data
function public.read_form(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local window_tags = flib_gui.get_tags(refs.window)

    ---@type atd.TrainTemplate
    local train_template = {}

    train_template.id = window_tags.train_template_id
    train_template.name = refs.name_input.text or mod_table.NIL
    train_template.icon = refs.icon_input.elem_value or mod_table.NIL
    -- TODO add chooser
    train_template.train_color = { 255, 255, 255}
    train_template.train =  train_builder_component.read_form(event)
    train_template.enabled = false
    train_template.amount = 0

    return train_template
end

function public.validate_form(event)
    local form_data = public.read_form(event)

    return flib_table.array_merge({
        train_builder_component.validate_form(event),
        validator.validate(VALIDATION_RULES, form_data)
    })
end

return public