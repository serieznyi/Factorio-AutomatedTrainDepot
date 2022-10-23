local flib_train = require("__flib__.train")

local logger = require("scripts.lib.logger")
local Train = require("scripts.lib.domain.entity.Train")
local persistence_storage = require("scripts.persistence.persistence_storage")

local TrainTaskService = {}

function TrainTaskService.init()
end

function TrainTaskService.load()
end

---@param train_template_id uint
---@return void
function TrainTaskService.enable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template.enabled = true

    train_template = persistence_storage.add_train_template(train_template)

    TrainTaskService._raise_train_template_changed_event(train_template)
end

---@param train_template_id uint
---@return void
function TrainTaskService.disable_train_template(train_template_id)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)
    train_template.enabled = false

    train_template = persistence_storage.add_train_template(train_template)

    TrainTaskService._raise_train_template_changed_event(train_template)
end

---@param train_template_id uint
---@param count int
---@return void
function TrainTaskService.change_trains_quantity(train_template_id, count)
    local train_template = persistence_storage.find_train_template_by_id(train_template_id)

    train_template:change_trains_quantity(count)
    persistence_storage.add_train_template(train_template)

    TrainTaskService._raise_train_template_changed_event(train_template)

    return train_template
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainTaskService._raise_train_template_changed_event(train_template)
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

return TrainTaskService