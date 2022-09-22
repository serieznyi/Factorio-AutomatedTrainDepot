---@param value string
local function hash_string(value)
    local hash = 1

    for c in string.gmatch(value, '.') do
        hash = hash + (string.byte(c) * 31)
    end

    return hash
end

---@param value number
local function hash_number(value)
    local str = tostring(value):gsub('%.', '')

    return tonumber(str)
end

---@param value boolean
local function hash_boolean(value)
    return value == true and 1 or 0
end

local hash = {}

--- Get hash code for table
---@param table table
---@return int
function hash.hash_code(table)
    if type(table) ~= "table" then
        return nil
    end

    local hash_code = 1

    for k, v in pairs(table) do
        hash_code = hash_code + hash.hash_value(k) + hash.hash_value(v)
    end

    return hash_code
end

function hash.hash_value(value)
    local hash_code
    local value_type = type(value)

    if value_type == "number" then
        hash_code = hash_number(value)
    elseif value_type == "string" then
        hash_code = hash_string(value)
    elseif value_type == "boolean" then
        hash_code = hash_boolean(value)
    elseif value_type == "nil" then
        hash_code = 1
    elseif value_type == "table" then
        hash_code = hash.hash_code(value)
    end

    return hash_code
end

return hash