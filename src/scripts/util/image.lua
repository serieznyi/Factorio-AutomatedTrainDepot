local image = {}

---@param item_name string
function image.image_path_for_item(item_name)
    local icon_path = "item/" .. item_name

    if not game.is_valid_sprite_path(icon_path) then
        icon_path = "utility/missing_icon"
    end

    return icon_path
end

---@param item_name string
function image.image_for_item(item_name)
    local icon_path = image.image_path_for_item(item_name)

    return "[img=" .. icon_path .. "]"
end

return image