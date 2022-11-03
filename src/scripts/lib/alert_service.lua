local logger = require("scripts.lib.logger")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")

local AlertService = {
    messages = {
        [atd.defines.alert_type.depot_storage_full] = {"depot-notifications.atd-no-free-space-in-depot-storage"},
    },
    icons = {
        [atd.defines.alert_type.depot_storage_full] = { type = "item", name = "locomotive" }, -- todo change icon
    }
}

---@param context scripts.lib.domain.Context
---@param alert_type mod.defines.alert_type
function AlertService.add(context, alert_type)
    local depot_storage_entity = remote.call("atd", "depot_get_storage", context)

    for _, player in ipairs(context:force().players) do
        player.add_custom_alert(
            depot_storage_entity,
            AlertService.icons[alert_type],
            AlertService.messages[alert_type],
            true
        )
    end
end

---@param context scripts.lib.domain.Context
---@param alert_type mod.defines.alert_type
function AlertService.remove(context, alert_type)
    local depot_storage_entity = remote.call("atd", "depot_get_storage", context)

    for _, player in ipairs(context:force().players) do
        player.remove_alert{
            entity = depot_storage_entity,
            message = AlertService.messages[alert_type],
        }
    end
end

return AlertService