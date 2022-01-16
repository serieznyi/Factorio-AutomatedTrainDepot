local mod_table = require("scripts.util.table")

local validator = {}

---@param value_data table
---@param message_arg string
function validator.empty(value_data, message_arg)
    local name = value_data.k
    local value = value_data.v
    local message = message_arg or {"validation-message.empty", name}

    if value == nil or value == "" or value == {}  or value == mod_table.NIL  then
        return message
    end

    return nil
end

return validator