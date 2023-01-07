local logger = require("scripts.lib.logger")

local AlertService = {
    messages = {
        [atd.defines.alert_type.depot_storage_full] = {"depot-notifications.atd-no-free-space-in-depot-storage"},
        [atd.defines.alert_type.depot_storage_not_contains_required_items] = { "depot-notifications.atd-depot-storage-not-contains-required-items"},
        [atd.defines.alert_type.depot_storage_not_contains_required_fuel] = { "depot-notifications.atd-depot-storage-not-contains-required-fuel"},
    },
    icons = {
        [atd.defines.alert_type.depot_storage_full] = { type = "item", name = atd.defines.prototypes.item.depot_building }, -- todo change icon
        [atd.defines.alert_type.depot_storage_not_contains_required_items] = { type = "item", name = atd.defines.prototypes.item.depot_building }, -- todo change icon
        [atd.defines.alert_type.depot_storage_not_contains_required_fuel] = { type = "item", name = atd.defines.prototypes.item.depot_building }, -- todo change icon
    }
}

---@param context scripts.lib.domain.Context
---@param alert_type mod.defines.alert_type
function AlertService.add(context, alert_type)
    local depot_entity = remote.call("atd", "depot_get_depot", context)

    for _, player in ipairs(context:force().players) do
        player.add_custom_alert(
            depot_entity,
            AlertService.icons[alert_type],
            AlertService.messages[alert_type],
            true
        )
    end
end

---@param context scripts.lib.domain.Context
---@param alert_type mod.defines.alert_type
function AlertService.remove(context, alert_type)
    local depot_entity = remote.call("atd", "depot_get_depot", context)

    for _, player in ipairs(context:force().players) do
        player.remove_alert{
            entity = depot_entity,
            message = AlertService.messages[alert_type],
        }
    end
end

return AlertService