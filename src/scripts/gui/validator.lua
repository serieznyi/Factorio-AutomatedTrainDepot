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

---@param rules table
---@param data table
---@return table
function validator.validate(rules, data)
    local validation_errors = {}

    for form_field_name, form_value in pairs(data) do
        for field_name, field_validators in pairs(rules) do
            if form_field_name == field_name then
                for _, field_validator in pairs(field_validators) do
                    local error = field_validator({k = form_field_name, v = form_value})

                    if error ~= nil then
                        table.insert(validation_errors, error)
                    end
                end
            end
        end
    end

    return validation_errors
end

return validator