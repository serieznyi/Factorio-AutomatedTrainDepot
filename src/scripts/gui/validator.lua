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

---@param field string Name of field what will check
---@param field function Check what rule allowed validate passed field data
---@param field function Validation function
function validator.check(field, match, check)
    return {
        field = field,
        match = match,
        check = check,
    }
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
    local data = flib_table.deep_copy(data_arg)

    for _, rule in ipairs(rules) do
        if rule.match(rule.field, data[rule.field]) then
            local error = rule.check(rule.field, data)

            if error ~= nil then
                table.insert(validation_errors, {field = rule.field, error = error})
            end
        end
    end

    return validation_errors
end

return validator