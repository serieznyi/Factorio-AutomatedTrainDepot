local gui = {}

local action_name_map

local function init()
    action_name_map = {}

    for action_name, action_number in pairs(mod.defines.gui.actions) do
        action_name_map[action_number] = action_name
    end
end

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

---@param action_number uint
function gui.action_name(action_number)
    if action_name_map == nil then
        init()
    end

    return action_name_map[action_number] or 'unknown(' .. action_number .. ')'
end

return gui