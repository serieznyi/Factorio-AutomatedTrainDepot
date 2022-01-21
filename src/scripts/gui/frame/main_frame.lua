local flib_gui = require("__flib__.gui")

local mod_gui = require("scripts.util.gui")

local FRAME_NAME = automated_train_depot.constants.gui.frame_names.main_frame
local FRAME_WIDTH = 1200;
local FRAME_HEIGHT = 600;

local ACTION = {
    CLOSE = automated_train_depot.constants.gui.common_actions.close,
    GROUP_SELECTED = "group_selected",
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
    ---@param player LuaPlayer
    ---@param refs table
    save_gui = function(player, refs)
        global.gui[FRAME_NAME][player.index] = {
            refs = refs,
        }
    end,
}

local frame = {}

---@return table
local function gui_build_structure_frame()
    return {
        type = "frame",
        name = FRAME_NAME,
        direction = "vertical",
        ref  =  {"window"},
        visible = false,
        style_mods = {
            natural_width = FRAME_WIDTH,
            natural_height = FRAME_HEIGHT,
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
                        caption = {"main-frame.atd-title"},
                        ignored_by_interaction = true
                    },
                    {
                        type = "empty-widget",
                        style = "flib_titlebar_drag_handle",
                        ignored_by_interaction = true
                    },
                    {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "atd_sprite_settings",
                        actions = {
                            on_click = {
                                gui = automated_train_depot.constants.gui.frame_names.settings_frame,
                                action = automated_train_depot.constants.gui.common_actions.open
                            }
                        }
                    },
                    {
                        type = "sprite-button",
                        style = "frame_action_button",
                        sprite = "utility/close_white",
                        hovered_sprite = "utility/close_black",
                        clicked_sprite = "utility/close_black",
                        actions = {
                            on_click = {gui = FRAME_NAME, action = ACTION.CLOSE}
                        }
                    },
                }
            },
            -- Content
            {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "flow",
                        direction = "vertical",
                        style_mods = {
                            minimal_width = FRAME_WIDTH * 0.25,
                            maximal_width = FRAME_WIDTH * 0.25,
                        },
                        children = {
                            {
                                type = "frame",
                                style = "inside_deep_frame",
                                children = {
                                    {
                                        type = "frame",
                                        style = "subheader_frame",
                                        style_mods = {
                                            horizontally_stretchable = true,
                                        },
                                        children = {
                                            {
                                                type = "sprite-button",
                                                style = "tool_button_green",
                                                tooltip = {"main-frame.atd-add-new-group"},
                                                sprite = "atd_sprite_add",
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.add_group_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.open,
                                                    },
                                                },
                                            },
                                            {
                                                type = "sprite-button",
                                                style = "tool_button",
                                                tooltip = {"main-frame.atd-edit-group"},
                                                ref = {"edit_group_button"},
                                                sprite = "atd_sprite_edit",
                                                enabled = false,
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.add_group_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.edit,
                                                    },
                                                },
                                            },
                                            {
                                                type = "sprite-button",
                                                style = "tool_button_red",
                                                tooltip = {"main-frame.atd-delete-group"},
                                                ref = {"delete_group_button"},
                                                sprite = "atd_sprite_trash",
                                                enabled = false,
                                                actions = {
                                                    on_click = {
                                                        gui = automated_train_depot.constants.gui.frame_names.main_frame,
                                                        action = automated_train_depot.constants.gui.common_actions.delete,
                                                    },
                                                },
                                            },
                                        }
                                    },
                                }
                            },
                            {
                                type = "flow",
                                direction = "vertical",
                                children = {
                                    {
                                        type = "frame",
                                        style = "inside_deep_frame",
                                        children = {
                                            {
                                                type = "scroll-pane",
                                                ref = {"groups_container"},
                                                style_mods = {
                                                    vertically_stretchable = true,
                                                    horizontally_stretchable = true,
                                                },
                                                style = "atd_scroll_pane_list_box",
                                            }
                                        }
                                    },
                                }
                            },
                        }
                    },
                    {
                        type = "flow",
                        style_mods = {
                            minimal_width = FRAME_WIDTH - (FRAME_WIDTH * 0.25),
                            maximal_width = FRAME_WIDTH - (FRAME_WIDTH * 0.25),
                        },
                        direction = "vertical",
                        children = {
                            {
                                type = "frame",
                                style_mods = {
                                    horizontally_stretchable = true,
                                    vertically_stretchable = true,
                                },
                                ref = {"content_frame"},
                                style = "inside_deep_frame",
                            }
                        }
                    }
                }
            }
        }
    }
end

---@param selected_element LuaGuiElement
---@param gui table
local function active_group_button(selected_element, gui)
    ---@param child LuaGuiElement
    for i, child in ipairs(gui.refs.groups_container.children) do
        if i ~= selected_element.get_index_in_parent() then
            flib_gui.update(child, {style = "atd_button_list_box_item"})
        else
            flib_gui.update(child, {style = "atd_button_list_box_item_active"})
        end
    end
end

---@param event EventData
local function select_group(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    active_group_button(event.element, gui)

    gui.refs.edit_group_button.enabled = true
    gui.refs.delete_group_button.enabled = true
end

---@param event EventData
local function delete_group(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)

    -- TODO
end

---@param player LuaPlayer
---@param container LuaGuiElement
local function populate_groups_list(player, container)
    -- todo get data from persistence
    if global.groups[player.surface.name] ~= nil then
        if global.groups[player.surface.name][player.force.name] ~= nil then
            mod_gui.clear_children(container)

            for _, group in pairs(global.groups[player.surface.name][player.force.name]) do
                local icon = mod_gui.image_from_item_name(group.icon)

                flib_gui.add(container, {
                    type = "button",
                    caption = icon .. " " .. group.name,
                    style = "atd_button_list_box_item",
                    actions = {
                        on_click = { gui = FRAME_NAME, action = ACTION.GROUP_SELECTED}
                    }
                })
            end
        end
    end

    -- todo select first group
end

---@param player LuaPlayer
local function update_gui(player)
    local gui = persistence.get_gui(player)

    populate_groups_list(player, gui.refs.groups_container)
end

---@param player LuaPlayer
local function create_for(player)
    local refs = flib_gui.build(player.gui.screen, {gui_build_structure_frame()})

    refs.window.force_auto_center()
    refs.titlebar_flow.drag_target = refs.window

    local resolution, scale = player.display_resolution, player.display_scale
    refs.window.location = {
        ((resolution.width - (FRAME_WIDTH * scale)) / 2),
        ((resolution.height - (FRAME_HEIGHT * scale)) / 2)
    }

    persistence.save_gui(player, refs)

    return persistence.get_gui(player)
end

---@return table
function frame.remote_interfaces()
    return {
        ---@param player LuaPlayer
        update = function(player) update_gui(player) end,
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

---@param player LuaPlayer
function frame.open(player)
    local gui = create_for(player)

    populate_groups_list(player, gui.refs.groups_container)

    local window = gui.refs.window
    window.bring_to_front()
    window.visible = true
    player.opened = window
end

---@param action table
---@param event EventData
function frame.dispatch(action, event)
    local processed = false

    local event_handlers = {
        { gui = FRAME_NAME, action = ACTION.CLOSE, func = function(_, e) return frame.close(e) end},
        { gui = FRAME_NAME, action = ACTION.GROUP_SELECTED, func = function(_, e) return select_group(e) end},
        { gui = FRAME_NAME, action = ACTION.DELETE_GROUP, func = function(_, e) return delete_group(e) end},
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

function frame.close(event)
    local player = game.get_player(event.player_index)
    local gui = persistence.get_gui(player)
    local window = gui.refs.window

    window.visible = false

    if player.opened == gui.refs.window then
        player.opened = nil
    end

    window.destroy()

    persistence.destroy(player)

    return true
end

return frame