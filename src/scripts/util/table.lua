local flib_table = require("__flib__.table")

local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param value string
function private.hash_string(value)
    local hash = 1

    for c in string.gmatch(value, '.') do
        hash = hash + (string.byte(c) * 31)
    end

    return hash
end

---@param value number
function private.hash_number(value)
    return private.number_to_integer(value)
end

---@param value boolean
function private.hash_boolean(value)
    return value == true and 1 or 0
end

function private.number_to_integer(value)
    local value_str = tostring(value)
    local fraction = string.match(value_str, '[%d]+[.]*([%d]*)')
    local fraction_size = fraction ~= "" and string.len(fraction) or 0
    local precision = tonumber("1" .. string.rep("0", fraction_size))

    return tonumber(value * precision)
end

function private.hash_value(value)
    local hash_code
    local value_type = type(value)

    if value_type == "number" then
        hash_code = private.hash_number(value)
    elseif value_type == "boolean" then
        hash_code = private.hash_boolean(value)
    elseif value_type == "string" then
        hash_code = private.hash_string(value)
    elseif value_type == "nil" then
        hash_code = 1
    elseif value_type == "table" then
        hash_code = public.hash_code(value)
    end

    return hash_code
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

public.NIL = "__mod__nil"

--- Convert table to string
---@param table_arg table
function public.to_string(table_arg)
    return serpent.block(table_arg)
end

--- Get hash code for table
---@param table_arg table
---@return int
function public.hash_code(table_arg)
    if type(table_arg) ~= "table" then
        return nil
    end

    local hash_code = 1
    local assoc = table_arg[1] == nil

    if assoc then
        for k, v in pairs(table_arg) do
            hash_code = hash_code + private.hash_string(k)

            hash_code = hash_code + private.hash_value(v)
        end
    else
        for _, v in ipairs(table_arg) do
            hash_code = private.hash_value(v)
        end
    end

    return hash_code
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