local flib_table = require("__flib__.table")

local _table = {}

_table.NIL = "__mod__nil"

---@param table_arg table
function _table.to_string(table_arg)
    return serpent.block(table_arg)
end

---@param arrays table
---@param assoc bool
function _table.array_merge(arrays, assoc)
    local associative = false

    if assoc == true then
        associative = true
    end

    local output = {}

    if associative then
        for _, array in ipairs(arrays) do
            for key, value in pairs(array) do
                output[key] = value
            end
        end

        return output
    end

    return flib_table.array_merge(arrays)
end

function _table.array_values(array)
    local values = {}

    for _, v in pairs(array) do
        table.insert(values, v)
    end

    return values
end

return _table