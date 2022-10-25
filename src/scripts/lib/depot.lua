local EventDispatcher = require("scripts.lib.event.EventDispatcher")
local Context = require("scripts.lib.domain.Context")
local persistence_storage = require("scripts.persistence.persistence_storage")
local trains_balancer = require("scripts.lib.train.trains_balancer")
local train_constructor = require("scripts.lib.train.train_constructor")
local logger = require("scripts.lib.logger")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")

local Depot = {}

function Depot.init()
    Depot._register_event_handlers()
end

function Depot.load()
    Depot._register_event_handlers()
end

---@param schedule TrainSchedule
function Depot.is_valid_schedule(schedule)
    local is_path_readable = false

    -- todo add realisation

    return is_path_readable
end

---@param task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function Depot._try_remove_completed_task(task, tick)
    if not task:is_state_completed() then
        return
    end

    local completed_since = tick - task.completed_at

    if completed_since > atd.defines.time_in_ticks.seconds_2 then
        task:delete()

        persistence_storage.trains_tasks.add(task)

        Depot._raise_task_changed_event(task)
    end
end

---@param train_task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function Depot._raise_task_changed_event(train_task)
    -- todo duplicity

    ---@type LuaForce
    local force = game.forces[train_task.force_name]

    for _, player in ipairs(force.players) do
        script.raise_event(
            atd.defines.events.on_core_train_task_changed,
            { train_task_id = train_task.id, player_index = player.index }
        )
    end

end

function Depot._get_depot_multiplier()
    return 1.0 -- todo depended from technologies
end

---@param train_template scripts.lib.domain.entity.template.TrainTemplate
---@return scripts.lib.domain.entity.Train
function Depot._try_choose_train_for_disband(train_template)
    local context = Context.from_model(train_template)
    local trains = persistence_storage.find_controlled_trains_for_template(context, train_template.id)

    -- todo add more logic for getting train (empty train, train in depot, ...)
    return #trains > 0 and trains[1] or nil
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
function Depot._try_bind_train_with_disband_task(task)
    -- todo add search train logic

    return false
end

---@param task scripts.lib.domain.entity.task.TrainDisbandTask
---@param tick uint
function Depot._process_disbanding_task(task, tick)
    -- Disband uncontrolled train
    if task:is_state_created() and task.train_id ~= nil then
        task:state_wait_train()
    end

    -- Disband controlled train
    if task:is_state_created() and task.train_id == nil then
        task:state_try_choose_train()
    end

    if task:is_state_try_choose_train() then
        if Depot._try_bind_train_with_disband_task(task) then
            task:state_wait_train()
        end
    end

    if task:is_state_wait_train() then
        -- todo add logic for drive train to depot
    end

    if task:is_state_disband() then
        -- todo add logic for disband train

        if false then
            task:state_completed()
        end
    end

    persistence_storage.trains_tasks.add(task)

    Depot._raise_task_changed_event(task)
end

---@param task scripts.lib.domain.entity.task.TrainFormTask
---@param tick uint
function Depot._process_form_task(task, tick)
    local multiplier = Depot._get_depot_multiplier()

    if not task:is_state_created() and not task:is_state_form() then
        return false
    end

    if task:is_state_created() then
        local train_template = persistence_storage.find_train_template_by_id(task.train_template_id)

        task:state_form(tick, multiplier, train_template)
    end

    if task:is_form_time_left(tick) then
        task:state_formed()
    end

    persistence_storage.trains_tasks.add(task)

    Depot._raise_task_changed_event(task)

    if task:is_state_formed() then
        -- todo raise event
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, train_constructor.construct)
    end

    return true
end

---@param data NthTickEventData
function Depot._train_manipulations(data)
    local tick = data.tick
    local tasks = persistence_storage.trains_tasks.find_all_tasks()

    for _, task in pairs(tasks) do
        if task.type == TrainFormTask.type then
            Depot._process_form_task(task, tick)
        elseif task.type == TrainDisbandTask.type then
            Depot._process_disbanding_task(task, tick)
        end

        Depot._try_remove_completed_task(task, data.tick)
    end

    if persistence_storage.trains_tasks.total_count_form_tasks() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, nil)
    end
end

function Depot._on_ntd_trains_manipulation()
    script.on_nth_tick(atd.defines.on_nth_tick.trains_manipulations, Depot._train_manipulations)
end

---@param e scripts.lib.event.Event
function Depot._handle_trains_manipulations(e)
    Depot._on_ntd_trains_manipulation()
end

function Depot._handle_trains_balancer_check_activity(e)
    Depot._trains_balancer_check_activity()
end

function Depot._handle_trains_constructor_check_activity(e)
    Depot._trains_constructor_check_activity()
end

function Depot._trains_balancer_check_activity()
    if persistence_storage.count_active_trains_templates() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, nil)
        logger.debug("Unregister trains balancer", {}, "depot")
    else
        script.on_nth_tick(atd.defines.on_nth_tick.balance_trains_count, trains_balancer.balance_trains_quantity)
        logger.debug("Register trains balancer", {}, "depot")
    end
end

function Depot._trains_constructor_check_activity()
    if persistence_storage.trains_tasks.count_form_tasks_ready_for_deploy() == 0 then
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, nil)
        logger.debug("Register trains constructor", {}, "depot")
    else
        script.on_nth_tick(atd.defines.on_nth_tick.trains_deploy, train_constructor.construct)
        logger.debug("Unregister trains constructor", {}, "depot")
    end
end

function Depot._register_event_handlers()
    local handlers = {
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return Depot._handle_trains_manipulations(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_template_changed),
            handler = function(e) return Depot._handle_trains_balancer_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_changed),
            handler = function(e) return Depot._handle_trains_balancer_check_activity(e) end,
        },
        {
            match = EventDispatcher.match_event(atd.defines.events.on_core_train_task_changed),
            handler = function(e) return Depot._handle_trains_constructor_check_activity(e) end,
        },
    }

    for _, h in ipairs(handlers) do
        EventDispatcher.register_handler(h.match, h.handler, "depot")
    end
end

return Depot