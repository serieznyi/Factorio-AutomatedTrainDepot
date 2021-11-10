local depot = require("extra.logic.services.depot")

local default_controller = {}

function default_controller:on_runtime_mod_setting_changed()
    -- TODO process different settings type

    modificationState.settings.refresh()
end

---@param eventData EventData
function default_controller:on_build_entity(eventData)
    local entity = eventData.created_entity

    if not entity or not entity.valid then
        return
    end

    if entity.name == modificationState.constants.entity_names.depot_building then
        depot:build(entity)
    end
end

---@param eventData EventData
function default_controller:on_deconstruct_entity(eventData)
    local entity = eventData.entity
    if not entity or not entity.valid then
        return
    end

    if entity.name == modificationState.constants.entity_names.depot_building then
        depot:destroy(entity)
    end
end

return default_controller