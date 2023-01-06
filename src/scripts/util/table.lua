local flib_table = require("__flib__.table")

local atd_table = {}

--- Convert table to string (table content view)
---@param table_arg table
function atd_table.to_string(table_arg)
    return serpent.block(table_arg)
end

---@param arrays table array of objects
function atd_table.objects_merge(arrays)
    local result = {}
    for _, array in ipairs(arrays) do
        for key, value in pairs(array) do
            result[key] = value
        end
    end

    return result
end

-- todo maybe wrong working. rewrite or remove
function atd_table.array_values(array)
    local values = {}

    for _, v in pairs(array) do
        table.insert(values, v)
    end

    return values
end

function atd_table.array_keys(array)
    local keys = {}

    for k, _ in pairs(array) do
        table.insert(keys, k)
    end

    return keys
end

---@param array table every row must realize __tostring
---@return table
function atd_table.array_unique(array)
    local result = {}

    for _, v in ipairs(array) do
        result[tostring(v)] = v
    end

    return flib_table.filter(result, function(v) return true end, true)
end

---@param target table table what will be filled
---@param source table source table for fill
function atd_table.fill_assoc(target, source)
    for k, v in pairs(source) do
        target[k] = v
    end
end

---@param table_arg table
---@return table reversed table
function atd_table.reverse(table_arg)
    local reversed = {}

    for i=#table_arg, 1, -1 do
        table.insert(reversed, table_arg[i])
    end

    return reversed
end

--- @param tbl table
--- @param filter function Takes in `value`, `key`, and `tbl` as parameters.
--- @param array_insert? boolean If true, the result will be constructed as an array of values that matched the filter. Key references will be lost.
--- @return table
--- @see __flib__.table.filter
function atd_table.filter(tbl, filter, array_insert)
    return flib_table.filter(tbl, filter, array_insert)
end

--- @param tbl table
--- @param mapper function Takes in `value`, `key`, and `tbl` as parameters.
--- @return table
--- @see __flib__.table.map
function atd_table.map(tbl, mapper)
    return flib_table.map(tbl, mapper)
end

--- @param tbl table The table to make a copy of.
--- @return table
---@see __flib__.table.deep_copy
function atd_table.deep_copy(tbl)
    return flib_table.deep_copy(tbl)
end

--- @param tbl table The table to search.
--- @param value any The value to match. Must have an `eq` metamethod set, otherwise will error.
--- @return any? key The first key corresponding to `value`, if any.
---@see __flib__.table.find
function atd_table.find(tbl, value)
    return flib_table.find(tbl, value)
end

return atd_table