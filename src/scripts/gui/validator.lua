local flib_table = require("__flib__.table")

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

---@param field_name string
---@param form table
---@param message_arg string
function validator.rule_empty(field_name, form, message_arg)
    local value = form[field_name]
    local message = message_arg or {"validation-message.empty", field_name}

    if value == nil or value == "" or value == {} or value == mod.util.table.NIL then
        return message
    end

    return nil
end

---@param container LuaGuiElement
---@param errors table
function validator.render_errors(container, errors)
    container.clear()

    for _, error in ipairs(errors) do
        container.add{
            type="label",
            caption=error.error,
            style="error_label"
        }
    end
end

---@param rules table
---@param data_arg table
---@return table
function validator.validate(rules, data_arg)
    local validation_errors = {}
    local data = flib_table. deep_copy(data_arg)

    for form_field_name, _ in pairs(data) do
        for _, validator_data_element in ipairs(rules) do
            if validator_data_element.match(form_field_name, data[form_field_name]) then
                for _, validator_rule in ipairs(validator_data_element.rules) do
                    local error = validator_rule(form_field_name, data)

                    if error ~= nil then
                        table.insert(validation_errors, {field = form_field_name, error = error})
                    end
                end
            end
        end
    end

    return validation_errors
end

return validator