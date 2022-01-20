local gui = {}

---@param element
function gui.clear_children(element)
    ---@param child LuaGuiElement
    for _, child in ipairs(element.children) do
        child.destroy()
    end
end

---@param item_name string
function gui.image_from_item_name(item_name)
    local item_prototype = game.item_prototypes[item_name]
    local icon_path = item_prototype.type .. "/" .. item_name

    if not game.is_valid_sprite_path(icon_path) then
        return "[img=utility/missing_icon]"
    end

    return "[img=" .. icon_path .. "]"
end

return gui