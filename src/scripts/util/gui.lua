local gui = {}

---@param element
function gui.clear_children(element)
    ---@param child LuaGuiElement
    for _, child in ipairs(element.children) do
        child.destroy()
    end
end

return gui