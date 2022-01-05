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
            direction = "vertical",
            name = frame_name,
            caption={"gui-name.automated-train-depot-main-frame"},
            auto_center = true,
            visible = true,
            style_mods = {
                size = { 385, 165 }
            },
            ref = { "frame" },
            --actions = {
            --    on_closed = { gui = "main", action = "close" },
            --},
            {
                type = "flow",
                --ref = { "titlebar", "flow" },
                --actions = {
                --    on_click = { gui = "main", transform = "handle_titlebar_click" },
                --},
            }

            --{
            --    type = "flow",
            --    style = "flib_titlebar_flow",
            --    ref = { "titlebar", "flow" },
            --    --actions = {
            --    --    on_click = { gui = "main", transform = "handle_titlebar_click" },
            --    --},
            --    { type = "label", style = "frame_title", caption = { "mod-name.LtnManager" }, ignored_by_interaction = true },
            --    { type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true },
            --    templates.frame_action_button(
            --            "ltnm_pin",
            --            { "gui.ltnm-keep-open" },
            --            { "titlebar", "pin_button" },
            --            { gui = "main", action = "toggle_pinned" }
            --    ),
            --    templates.frame_action_button(
            --            "ltnm_refresh",
            --            { "gui.ltnm-refresh-tooltip" },
            --            { "titlebar", "refresh_button" },
            --            { gui = "main", transform = "handle_refresh_click" }
            --    ),
            --    templates.frame_action_button(
            --            "utility/close",
            --            { "gui.close-instruction" },
            --            nil,
            --            { gui = "main", action = "close" }
            --    ),
            --},
            --{
            --    type = "frame",
            --    style = "inside_deep_frame",
            --    direction = "vertical",
            --    {
            --        type = "frame",
            --        style = "ltnm_main_toolbar_frame",
            --        { type = "label", style = "subheader_caption_label", caption = { "gui.ltnm-search-label" } },
            --        {
            --            type = "textfield",
            --            clear_and_focus_on_right_click = true,
            --            ref = { "toolbar", "text_search_field" },
            --            actions = {
            --                on_text_changed = { gui = "main", action = "update_text_search_query" },
            --            },
            --        },
            --        { type = "empty-widget", style = "flib_horizontal_pusher" },
            --        { type = "label", style = "caption_label", caption = { "gui.ltnm-network-id-label" } },
            --        {
            --            type = "textfield",
            --            style_mods = { width = 120 },
            --            numeric = true,
            --            allow_negative = true,
            --            clear_and_focus_on_right_click = true,
            --            text = "-1",
            --            ref = { "toolbar", "network_id_field" },
            --            actions = {
            --                on_text_changed = { gui = "main", action = "update_network_id_query" },
            --            },
            --        },
            --        { type = "label", style = "caption_label", caption = { "gui.ltnm-surface-label" } },
            --        {
            --            type = "drop-down",
            --            ref = { "toolbar", "surface_dropdown" },
            --            actions = {
            --                on_selection_state_changed = { gui = "main", action = "change_surface" },
            --            },
            --        },
            --    },
            --    {
            --        type = "tabbed-pane",
            --        style = "ltnm_tabbed_pane",
            --        trains_tab.build(widths),
            --        depots_tab.build(widths),
            --        stations_tab.build(widths),
            --        inventory_tab.build(),
            --        history_tab.build(widths),
            --        alerts_tab.build(widths),
            --    },
            --},
        },
    })

    automated_train_depot.logger:debug("Frame " .. frame_name .. " was build")

    self.frame = self.gui.frame
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