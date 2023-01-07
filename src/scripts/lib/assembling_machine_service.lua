local persistence_storage = require("scripts.persistence.persistence_storage")

local AssemblingMachineService = {}

---@param context scripts.lib.domain.Context
function AssemblingMachineService.balance(context)
    local depot_entity = remote.call("atd", "depot_get_depot", context)
    local count_active_form_tasks = persistence_storage.trains_tasks.count_active_disband_tasks(context)
    local count_active_disband_tasks = persistence_storage.trains_tasks.count_active_form_tasks(context)
    local active_tasks = count_active_form_tasks + count_active_disband_tasks

    if active_tasks > 0 then
        depot_entity.set_recipe(atd.defines.prototypes.recipe.depot_working_imitation)
    else
        depot_entity.set_recipe(nil)
    end

    local module_inventory = depot_entity.get_module_inventory()

    module_inventory.clear()

    if count_active_form_tasks > 1 then
        module_inventory.insert({name="atd-depot-module", count=count_active_form_tasks - 1})
    end

    if count_active_disband_tasks > 1 then
        module_inventory.insert({name="atd-depot-module", count=count_active_disband_tasks - 1})
    end
end

return AssemblingMachineService