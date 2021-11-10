-- assumes the tbl is an array, i.e., all the keys are
-- successive integers - otherwise #tbl will fail
function enum(table)
    local length = #table
    for i = 1, length do
        local v = table[i]
        table[v] = i
    end

    return table
end