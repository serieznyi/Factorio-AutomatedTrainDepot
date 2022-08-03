-- Interface for autocomplete in code

---@module gui.frame.Frame
local Frame = {
    ---@type string
    name = nil
}

---@return void
function Frame:destroy() end

---@return LuaGuiElement
function Frame:window() end

---@return void
function Frame:bring_to_front() end