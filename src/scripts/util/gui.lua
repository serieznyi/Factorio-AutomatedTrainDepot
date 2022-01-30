local gui = {}

local action_name_map

local function init()
    action_name_map = {}

    for action_name, action_number in pairs(mod.defines.gui.actions) do
        action_name_map[action_number] = action_name
    end
end

---@param element
---@deprecated use element.clean()
function gui.clear_children(element)
    ---@param child LuaGuiElement
    for _, child in ipairs(element.children) do
        child.destroy()
    end
end

---@param item_name string
function gui.image_path_for_item(item_name)
    local icon_path = "item/" .. item_name

    if not game.is_valid_sprite_path(icon_path) then
        icon_path = "utility/missing_icon"
    end

    return icon_path
end

---@param item_name string
function gui.image_for_item(item_name)
    local icon_path = gui.image_path_for_item(item_name)

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