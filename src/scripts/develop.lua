local develop = {}

---@param table table
---@return string
---@see https://github.com/ClaudeMetz/FactoryPlanner
---@author Claude Metz
function develop.table_to_string(table)
    local excludes = LLOG_EXCLUDES or {}  -- Optional custom excludes defined by the parent mod

    if type(table) ~= "table" then return (tostring(table)) end

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
            local el = tostring(value)
            if type(value) == "string" then
                el = "'" .. el .. "'"
            elseif type(value) == "table" then
                if excludes[name] ~= nil then
                    el = value.name or "EXCLUDE"
                else
                    el = format(value, depth+tab_width)
                end
            end

            local comma = (first_element) and "" or ","
            first_element = false

            -- Print string and discontinuous numerical keys only
            local key = (type(name) == "number" and preceding_name+1 == name) and "" or (name .. " = ")
            preceding_name = name

            out = out .. comma .. "\n" .. super_spacing .. key .. el
        end

        return (out .. "\n" .. spacing .. "}")
    end

    return format(table, 0)
end

return develop