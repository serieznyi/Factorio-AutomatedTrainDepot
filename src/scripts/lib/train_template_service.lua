local logger = require("scripts.lib.logger")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")

local TrainTemplateService = {}

function TrainTemplateService.init()
end

function TrainTemplateService.load()
end

---@param train_template_id uint
---@param train_template_dto scripts.lib.domain.entity.template.TrainTemplate
---@param player_index uint
function TrainTemplateService.update_train_template(train_template_id, train_template_dto, player_index)
    assert(train_template_id, "train_template_id is nil")
    assert(train_template_dto, "train_template_form is nil")
    assert(player_index, "player_index is nil")

    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    assert(train_template, "train_template not found")

    train_template.name = train_template_dto.name
    train_template.icon = train_template_dto.icon
    train_template.train_color = train_template_dto.train_color
    train_template.train = train_template_dto.train
    train_template.clean_station = train_template_dto.clean_station
    train_template.destination_schedule = train_template_dto.destination_schedule
    train_template.use_any_fuel = train_template_dto.use_any_fuel
    train_template.fuel = train_template_dto.fuel

    persistence_storage.add_train_template(train_template)

    script.raise_event(atd.defines.events.on_core_train_template_changed, {
        player_index = player_index,
        train_template_id = train_template.id
    })
end

---@param train_template_dto scripts.lib.domain.entity.template.TrainTemplate
---@param player_index uint
function TrainTemplateService.create_train_template(train_template_dto, player_index)
    assert(train_template_dto, "train_template_form is nil")
    assert(player_index, "player_index is nil")

    persistence_storage.add_train_template(train_template_dto)

    script.raise_event(atd.defines.events.on_core_train_template_changed, {
        player_index = player_index,
        train_template_id = train_template_dto.id
    })
end

---@param train_template_id uint
---@return uint
function TrainTemplateService.planned_quantity_form_tasks(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    local context = Context.from_model(train_template)
    local tasks_quantity = persistence_storage.trains_tasks.count_form_tasks(context, train_template.id)
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