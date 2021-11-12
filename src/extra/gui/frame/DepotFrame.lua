local gui = require("__flib__.gui")

---@class DepotFrame
local DepotFrame = {
    ---@type LuaEntity entity_depot
    entity_depot = 1,
    ---@type LuaPlayer player
    player = nil,
    ---@type LuaGuiElement frame
    frame = nil,
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

local function build()
    DepotFrame.frame = DepotFrame.player.gui.screen.add{
        type="frame",
        name="automated-train-depot-main-frame",
        caption={"gui-name.automated-train-depot-main-frame"},
    }

    DepotFrame.frame.style.size = {385, 165}
    DepotFrame.frame.auto_center = true


end

setmetatable(DepotFrame, {
    ---@param self table
    ---@param entity LuaEntity
    ---@param player LuaPlayer
    __call = function(self, entity, player)
        self.entity_depot = entity
        self.player = player

        build()

        return self
    end
})

return DepotFrame