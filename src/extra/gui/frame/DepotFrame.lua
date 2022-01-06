local gui = require("__flib__.gui")

---@class DepotFrame
local DepotFrame = {
    ---@type LuaEntity entity_depot
    entity_depot = nil,
    ---@type LuaPlayer player
    player = nil,
    ---@type LuaGuiElement frame
    frame = nil,
    ---@type
    gui = nil

}

local function build_tab_main()
    return {
        type = "tab",
        caption = { "ui-name.automated-train-depot-general-tab" },
        --ref = { "general", "tab" },
        --actions = {
        --    on_click = { gui = "main", action = "change_tab", tab = "general" },
        --},
        --content = {
        --    type = "frame",
        --}
    }
end

local function build_tabbed_pane()
    return {
        type = "tabbed-pane",
    }
end

function DepotFrame:__initialization()
    local frame_name = "automated-train-depot-main-frame-" .. tostring(self.entity_depot.unit_number)

    self.gui = gui.build(self.player.gui.screen, {
        {
            type = "frame",
            name = "depot_main_frame",
            direction = "vertical",
            ref  =  {"window"},
            style_mods = {
                natural_width = 1200,
                natural_height = 400,
            },
            actions = {
                --on_closed = {gui = "demo", action = "close"} -- TODO
            },
            children = {
                -- Titlebar
                {
                    type = "flow",
                    ref = {"titlebar", "flow"},
                    children = {
                        {
                            type = "label",
                            style = "frame_title",
                            caption = {"gui-name.automated-train-depot-main-frame"},
                            ignored_by_interaction = true
                        },
                        {
                            type = "empty-widget",
                            style = "flib_titlebar_drag_handle",
                        },
                        {
                            type = "sprite-button",
                            style = "frame_action_button",
                            sprite = "utility/close_white",
                            hovered_sprite = "utility/close_black",
                            clicked_sprite = "utility/close_black",
                            ref = {"titlebar", "close_button"},
                            actions = {
                                on_click = {target = "depot_main_frame", action = "close"}
                            }
                        }
                    }
                },
                -- Content
                {
                    type = "frame",
                    style = "inside_deep_frame_for_tabs",
                }
            }
        }
    })

    automated_train_depot.logger:debug("Frame " .. frame_name .. " was build")

    self.frame = self.gui.window
    self.frame.force_auto_center()
end

setmetatable(DepotFrame, {
    ---@param _ table
    ---@param entity LuaEntity
    ---@param player LuaPlayer
    __call = function(_, entity, player)
        ---@type DepotFrame
        local self = {}
        setmetatable(self, { __index = DepotFrame })

        self.entity_depot = entity
        self.player = player

        self:__initialization()

        return self
    end
})

return DepotFrame