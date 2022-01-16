local table = {}

---@param table_arg table
function table.to_string(table_arg)
    return serpent.block(table_arg)
end

return table