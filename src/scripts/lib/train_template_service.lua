local logger = require("scripts.lib.logger")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")

local TrainTemplateService = {}

function TrainTemplateService.init()
end

function TrainTemplateService.load()
end

---@param train_template_id uint
---@return uint
function TrainTemplateService.planned_quantity_form_tasks(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    local context = Context.from_model(train_template)
    local tasks_quantity = persistence_storage.trains_tasks.count_forming_tasks(context, train_template.id)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)

    return train_template.trains_quantity - tasks_quantity - #trains
end

---@param train_template_id uint
---@return uint
function TrainTemplateService.planned_quantity_disband_tasks(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    local context = Context.from_model(train_template)
    local tasks_quantity = persistence_storage.trains_tasks.count_disband_tasks(context, train_template.id)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)

    return #trains - train_template.trains_quantity - tasks_quantity
end

---@param train_template_id uint
---@return void
function TrainTemplateService.enable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template.enabled = true

    train_template = persistence_storage.add_train_template(train_template)

    TrainTemplateService._raise_train_template_changed_event(train_template)
end

---@param train_template_id uint
---@return void
function TrainTemplateService.disable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    train_template.enabled = false

    train_template = persistence_storage.add_train_template(train_template)

    TrainTemplateService._raise_train_template_changed_event(train_template)
end

---@param train_template_id uint
---@param count int
---@return void
function TrainTemplateService.change_trains_quantity(train_template_id, count)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template:change_trains_quantity(count)
    persistence_storage.add_train_template(train_template)

    TrainTemplateService._raise_train_template_changed_event(train_template)

    return train_template
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainTemplateService._raise_train_template_changed_event(train_template)
    logger.debug(
            "Changed train template (`1`)",
            { train_template.id },
            "depot"
    )

    ---@type LuaForce
    local force = game.forces[train_template.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
                atd.defines.events.on_core_train_template_changed,
                { player_index = player.index, train_template_id = train_template.id }
        )
    end

end

return TrainTemplateService