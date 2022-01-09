local util = {}

local function _llog(table_to_print)
    local excludes = LLOG_EXCLUDES or {}  -- Optional custom excludes defined by the parent mod

    if type(table_to_print) ~= "table" then return (tostring(table_to_print)) end

    local tab_width, super_space = 2, ""
    for _=0, tab_width-1, 1 do super_space = super_space .. " " end

    local function format(table_part, depth)
        if table_size(table_part) == 0 then return "{}" end

        local spacing = ""
        for _=0, depth-1, 1 do spacing = spacing .. " " end
        local super_spacing = spacing .. super_space

        local out, first_element = "{", true
        local preceding_name = 0

        for name, value in pairs(table_part) do
            local element = tostring(value)
            if type(value) == "string" then
                element = "'" .. element .. "'"
            elseif type(value) == "table" then
                if excludes[name] ~= nil then
                    element = value.name or "EXCLUDE"
                else
                    element = format(value, depth+tab_width)
                end
            end

            local comma = (first_element) and "" or ","
            first_element = false

            -- Print string and continuous numerical keys only
            local key = (type(name) == "number" and preceding_name+1 ~= name) and "" or (name .. " = ")
            preceding_name = name

            out = out .. comma .. "\n" .. super_spacing .. key .. element
        end

        return (out .. "\n" .. spacing .. "}")
    end

    return format(table_to_print, 0)
end


---@param element LuaGuiElement
---@param player_index int
function util.disable_all_gui_except(element, player_index)
    for group_name, gui_group in pairs(global.gui) do
        ---@param gui LuaGuiElement
        for gui_player_index, gui in pairs(gui_group) do
            if gui_player_index == player_index then
                --if element ~= gui then
                    automated_train_depot.console:debug(group_name .. " - " .. tostring(gui_player_index))
                    gui.enabled = false
                --end
            end
        end
    end
end

function util.enable_all_gui()
    for _, guiGroup in pairs(global.gui) do
        ---@param gui LuaGuiElement
        for gui_player_index, gui in pairs(guiGroup) do
            if gui_player_index == player_index then
                gui.enabled = true
            end
        end
    end
end

return util;