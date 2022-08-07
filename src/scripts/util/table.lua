local flib_table = require("__flib__.table")

local public = {}

public.NIL = "__mod__nil"

--- Convert table to string (table content view)
---@param table_arg table
function public.to_string(table_arg)
    return serpent.block(table_arg)
end

---@param arrays table array of objects
function public.objects_merge(arrays)
    local result = {}
    for _, array in ipairs(arrays) do
        for key, value in pairs(array) do
            result[key] = value
        end
    end

    return result
end

function public.array_values(array)
    local values = {}

    for _, v in pairs(array) do
        table.insert(values, v)
    end

    return values
end

---@param array table
---@return table
function public.array_unique(array)
    local result = {}

    for _, v in ipairs(array) do
        result[v] = v
    end

    return flib_table.filter(result, function(v) return true end, true)
end

return public