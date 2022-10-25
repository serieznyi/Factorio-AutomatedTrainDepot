local flib_table = require("__flib__.table")

local Context = require("scripts.lib.domain.Context")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local persistence_storage = require("scripts.persistence.persistence_storage")
local logger = require("scripts.lib.logger")

local TrainsBalancer = {}

---@param data NthTickEventData
function TrainsBalancer.balance_trains_quantity(data)
    local contexts_with_depot = TrainsBalancer._find_contexts_with_depot()

    for _, c in ipairs(contexts_with_depot) do
        TrainsBalancer._balance_trains_count_for_context(c, data)
    end
end

function TrainsBalancer._find_contexts_with_depot()
    return flib_table.filter(
            persistence_storage.find_contexts_from_train_templates(),
            function(c)
                return persistence_storage.is_depot_exists_at(c)
            end,
            true
    )
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainsBalancer._calculate_trains_diff(train_template)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)
    local form_tasks_quantity = persistence_storage.trains_tasks.count_active_form_tasks(context, train_template.id)
    local disband_tasks_quantity = persistence_storage.trains_tasks.count_active_disband_tasks(context, train_template.id)
    local potential_trains_quantity = #trains + form_tasks_quantity - disband_tasks_quantity

    return train_template.trains_quantity - potential_trains_quantity
end

---@param context scripts.lib.domain.Context
---@param _ NthTickEventData
function TrainsBalancer._balance_trains_count_for_context(context, _)
    local train_templates = persistence_storage.find_enabled_train_templates(context)

    ---@param train_template scripts.lib.domain.entity.template.TrainTemplate
    for _, train_template in pairs(train_templates) do
        local trains_quantity_diff = TrainsBalancer._calculate_trains_diff(train_template)

        if trains_quantity_diff > 0 then
            TrainsBalancer._form_train(train_template, trains_quantity_diff)
        elseif trains_quantity_diff < 0 then
            TrainsBalancer._disband_train(train_template, trains_quantity_diff * -1)
        end
    end
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param missing_amount_trains uint
function TrainsBalancer._form_train(train_template, missing_amount_trains)
    for _ = 1, missing_amount_trains do
        if not TrainsBalancer._try_cancel_disband_train_task(train_template) then
            break
        end

        missing_amount_trains = missing_amount_trains - 1
    end

    if missing_amount_trains > 0 then
        TrainsBalancer._try_add_form_train_task(train_template)
    end
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@param number_of_unnecessary_trains uint
function TrainsBalancer._disband_train(train_template, number_of_unnecessary_trains)

    for _ = 1, number_of_unnecessary_trains do
        if not TrainsBalancer._try_cancel_form_train_task(train_template) then
            break
        end

        number_of_unnecessary_trains = number_of_unnecessary_trains - 1
    end

    if number_of_unnecessary_trains > 0 then
        TrainsBalancer._try_add_disband_train_task(train_template)
    end
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainsBalancer._try_add_disband_train_task(train_template)
    -- todo balance tasks for different forces, surfaces and templates
    local context = Context.from_model(train_template)

    if not TrainsBalancer._has_free_disband_slot(context) then
        return false
    end

    local task = TrainDisbandTask.from_train_template(train_template)

    persistence_storage.trains_tasks.add(task)

    TrainsBalancer._raise_task_changed_event(task)

    logger.debug(
            "Add new disband task `{1}` for template `{2}`",
            { task.id, train_template.name},
            "depot"
    )

    return true
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainsBalancer._try_cancel_disband_train_task(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.trains_tasks.find_disbanding_tasks(context, train_template.id)

    for _, task in pairs(tasks) do
        if task:can_cancel() then
            TrainsBalancer._cancel_task(task)

            return true
        end
    end

    return false
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainsBalancer._try_add_form_train_task(train_template)
    -- todo balance tasks for different forces, surfaces and templates
    local context = Context.from_model(train_template)

    if not TrainsBalancer._has_free_form_slot(context) then
        return false
    end

    local form_task = TrainFormTask.from_train_template(train_template)

    persistence_storage.trains_tasks.add(form_task)

    TrainsBalancer._raise_task_changed_event(form_task)

    return true
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
function TrainsBalancer._try_cancel_form_train_task(train_template)
    local context = Context.from_model(train_template)
    local tasks = persistence_storage.trains_tasks.find_form_tasks(context, train_template.id)

    for _, task in pairs(tasks) do
        if task:can_cancel() then
            TrainsBalancer._cancel_task(task)

            return true
        end
    end

    return false
end

---@param context scripts.lib.domain.Context
---@return bool
function TrainsBalancer._has_free_form_slot(context)
    local tasks_count = persistence_storage.trains_tasks.count_form_tasks(context)
    local slots_count = TrainsBalancer._get_form_slots_total_count()

    return slots_count > tasks_count
end

---@param context scripts.lib.domain.Context
---@return bool
function TrainsBalancer._has_free_disband_slot(context)
    local tasks_count = persistence_storage.trains_tasks.count_disband_tasks(context)
    local slots_count = TrainsBalancer._get_disband_slots_total_count()

    return slots_count > tasks_count
end

function TrainsBalancer._get_form_slots_total_count()
    return 2 -- todo depend from technologies
end

function TrainsBalancer._get_disband_slots_total_count()
    return 2 -- todo depend from technologies
end

---@param task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function TrainsBalancer._cancel_task(task)
    task:delete()

    persistence_storage.trains_tasks.add(task)

    TrainsBalancer._raise_task_changed_event(task)
end

---@param task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function TrainsBalancer._raise_task_changed_event(task)
    ---@type LuaForce
    local force = game.forces[task.force_name]

    logger.debug(
            "Changed train task (`1`) `{2}` for template `{3}`",
            { task.type, task.id, task.train_template_id },
            "train_balancer"
    )

    for _, player in ipairs(force.players) do
        script.raise_event(
                atd.defines.events.on_core_train_task_changed,
                { train_task_id = task.id, player_index = player.index }
        )
    end
end

return TrainsBalancer