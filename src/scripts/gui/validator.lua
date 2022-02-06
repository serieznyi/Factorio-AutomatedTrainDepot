local validator = {}

function validator.match_by_name(names_for_compare)
    return function(name_for_check)
        for _, name in ipairs(names_for_compare) do
            if name_for_check == name then
                return true
            end
        end

        return false
    end
end

function validator.match_any()
    return function(name)
        return true
    end
end

---@param value_data table
---@param message_arg string
function validator.rule_empty(value_data, message_arg)
    local name = value_data.k
    local value = value_data.v
    local message = message_arg or {"validation-message.empty", name}

    if value == nil or value == "" or value == {}  or value == mod.util.table.NIL  then
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
        for _, validator_data_element in ipairs(rules) do
            if validator_data_element.match(form_field_name, data[form_field_name]) then
                for _, validator_rule in ipairs(validator_data_element.rules) do
                    local error = validator_rule({k = form_field_name, v = form_value})

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