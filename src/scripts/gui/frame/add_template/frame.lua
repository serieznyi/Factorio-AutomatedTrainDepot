local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local mod_event = require("scripts.util.event")
local TrainTemplate = require("scripts.lib.domain.TrainTemplate")
local Context = require("scripts.lib.domain.Context")
local TrainStationSelector = require("scripts.gui.component.train_station_selector.component")
local constants = require("scripts.gui.frame.add_template.constants")
local build_structure = require("scripts.gui.frame.add_template.build_structure")
local train_builder_component = require("scripts.gui.frame.add_template.component.train_builder.component")
local validator = require("scripts.gui.validator")
local persistence_storage = require("scripts.persistence_storage")

local FRAME = constants.FRAME

---@type gui.component.TrainStationSelector
local clean_train_station_dropdown_component
---@type gui.component.TrainStationSelector
local destination_train_station_dropdown_component

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

    private.update_form(player)

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
function private.handle_form_changed(event)
    local player = game.get_player(event.player_index)
    local refs = storage.refs(player)
    local submit_button = refs.submit_button
    local validation_errors = private.validate_form(player)

    validator.render_errors(refs.validation_errors_container, validation_errors)

    submit_button.enabled = #validation_errors == 0

    return true
end

---@param event EventData
function private.handle_save_form(event)
    local player = game.get_player(event.player_index)
    local form_data = public.read_form(player)
    local validation_errors = private.validate_form(player)

    if #validation_errors == 0 then
        local train_template = persistence_storage.add_train_template(form_data)

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
---@param train_template scripts.lib.domain.TrainTemplate
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
    local train_template = persistence_storage.get_train_template(train_template_id)

    local refs = flib_gui.build(player.gui.screen, {build_structure.get(train_template)})

    clean_train_station_dropdown_component = TrainStationSelector.new(
            player.surface,
            player.force,
            { on_selection_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form } },
            train_template and train_template.clean_station or nil,
            true
    )
    clean_train_station_dropdown_component:build(refs.clean_train_station_dropdown_wrapper)

    destination_train_station_dropdown_component = TrainStationSelector.new(
            player.surface,
            player.force,
            { on_selection_state_changed = { target = FRAME.NAME, action = mod.defines.gui.actions.touch_form }},
            train_template and train_template.destination_station or nil,
            true
    )
    destination_train_station_dropdown_component:build(refs.target_train_station_dropdown_wrapper)

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

---@param player LuaPlayer
function private.update_form(player)
    local refs = storage.refs(player)
    local submit_button = refs.submit_button
    local validation_errors = private.validate_form(player)

    validator.render_errors(refs.validation_errors_container, validation_errors)

    submit_button.enabled = #validation_errors == 0

    return true
end

function private.validation_rules()
    return {
        {
            match = validator.match_by_name({"name"}),
            rules = { validator.rule_empty },
        },
        {
            match = validator.match_by_name({"icon"}),
            rules = { validator.rule_empty },
        },
        {
            match = validator.match_by_name({"clean_station"}),
            rules = { private.validation_not_same },
        },
    }
end

---@param field_name string
---@param form table
function private.validation_not_same(field_name, form)
    local value1 = form["clean_station"]
    local value2 = form["destination_station"]

    if value1 ~= nil and value1 ~= "" and value1 == value2 then
        return {"validation-message.cant-be-equals", "default_clean_station", "default_destination_station"}
    end

    return nil
end

---@param player LuaPlayer
function private.validate_form(player)
    local form_data = public.read_form(player)

    return flib_table.array_merge({
        train_builder_component.validate_form(player),
        clean_train_station_dropdown_component:validate_form(),
        destination_train_station_dropdown_component:validate_form(),
        validator.validate(private.validation_rules(), form_data)
    })
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
    train_builder_component.on_changed(private.handle_form_changed)
end

function public.load()
    train_builder_component.on_changed(private.handle_form_changed)
end

---@param action table
---@param event EventData
function public.dispatch(event, action)
    local handlers = {
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.touch_form,            func = private.handle_form_changed },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.close_frame,           func = private.handle_frame_close },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.open_frame,            func = private.handle_frame_open },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.edit_train_template,   func = private.handle_frame_open },
        { target = FRAME.NAME,                      action = mod.defines.gui.actions.save_form,             func = private.handle_save_form },
        { target = train_builder_component.name(),  action = mod.defines.gui.actions.any,                   func = train_builder_component.dispatch },
    }

    return mod_event.dispatch(handlers, event, action, FRAME.NAME)
end

---@param player LuaPlayer
---@return scripts.lib.domain.TrainTemplate form data
function public.read_form(player)
    local refs = storage.refs(player)
    local window_tags = flib_gui.get_tags(refs.window)
    local context = Context.from_player(player)
    ---@type scripts.lib.domain.TrainTemplate
    local train_template = TrainTemplate.from_context(window_tags.train_template_id, context)

    train_template.name = refs.name_input.text or mod.util.table.NIL
    train_template.icon = refs.icon_input.elem_value or mod.util.table.NIL
    -- TODO add chooser
    train_template.train_color = { 255, 255, 255}
    train_template.train =  train_builder_component.read_form(player)
    train_template.enabled = false
    train_template.clean_station = clean_train_station_dropdown_component:read_form()
    train_template.destination_station = destination_train_station_dropdown_component:read_form()
    train_template.trains_quantity = 0

    return train_template
end

return public