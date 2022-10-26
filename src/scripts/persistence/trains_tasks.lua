local util_table = require("scripts.util.table")
local logger = require("scripts.lib.logger")
local TrainFormTask = require("scripts.lib.domain.entity.task.TrainFormTask")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local Sequence = require("scripts.lib.Sequence")
local garbage_collector = require("scripts.persistence.garbage_collector")

local public = {}

---@type scripts.lib.Sequence
local train_task_sequence

---@param context scripts.lib.domain.Context
---@return function
local function match_context(context)
    return function(v)
        if context == nil then
            return true
        end

        return context:is_same(v.surface_name, v.force_name)
    end
end

---@return function
local function match_type_disband()
    return function(v)
        return v.type == TrainDisbandTask.defines.type
    end
end

---@return function
local function match_type_form()
    return function(v)
        return v.type == TrainFormTask.defines.type
    end
end

---@param v table
---@return function
local function match_not_deleted()
    return function(v)
        return v.deleted == false
    end
end

---@param v table
---@param train_template_id uint
---@return bool
local function match_train_template_id(train_template_id)
    return function(v)
        if train_template_id == nil then
            return true
        end

        return v.train_template_id == train_template_id
    end
end

---@param state string
---@return function
local function match_state(...)
    local args = {...}

    return function(v)
        for _, state in ipairs(args) do
            if v.state == state then
                return true
            end
        end

        return false
    end
end

---@param func function
---@return function
local function match_not(func)
    return function(v)
        return not func(v)
    end
end

local function rows(...)
    local filtered = global.trains_tasks

    for _, v in ipairs{...} do
        filtered = util_table.filter(filtered, v, true)
    end

    return util_table.array_values(filtered)
end

---@param task_data table
---@return scripts.lib.domain.entity.task.TrainDisbandTask|scripts.lib.domain.entity.task.TrainFormTask|nil
local function hydrate_task(task_data)
    if task_data.type == TrainFormTask.type then
        return TrainFormTask.from_table(task_data)
    end

    if task_data.type == TrainDisbandTask.type then
        return TrainDisbandTask.from_table(task_data)
    end

    assert(nil, "unknown task type")
end

---@param row table
---@return scripts.lib.domain.entity.task.TrainDisbandTask|scripts.lib.domain.entity.task.TrainFormTask|nil
local function hydrate(row)
    return util_table.map(row, hydrate_task)
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

function public.init()
    global.sequence.train_task = 1

    train_task_sequence = Sequence(global.sequence.train_task, function(value)
        global.sequence.train_task = value
    end)

    global.trains_tasks = {}

    logger.debug("trains_tasks was initialized")
end

function public.load()
    train_task_sequence = Sequence(global.sequence.train_task, function(value)
        global.sequence.train_task = value
    end)
end

---@param train_task scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@return scripts.lib.domain.entity.task.TrainFormTask|scripts.lib.domain.entity.task.TrainDisbandTask
function public.add(train_task)
    assert(train_task, "train-task is nil")

    if train_task.id == nil then
        train_task.id = train_task_sequence:next()
    end

    local data = train_task:to_table()

    global.trains_tasks[train_task.id] = garbage_collector.with_updated_at(data)

    return train_task
end

---@param train_template_id uint
---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.task.TrainFormTask[]
function public.find_form_tasks(context, train_template_id)
    assert(context, "context is nil")
    assert(train_template_id, "train_template_id is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_form(),
        match_train_template_id(train_template_id)
    )

    return hydrate(filtered)
end

---@param train_template_id uint
---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_disbanding_tasks(context, train_template_id)
    assert(context, "context is nil")
    assert(train_template_id, "train_template_id is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_disband(),
        match_train_template_id(train_template_id)
    )

    return hydrate(filtered)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint|nil
---@return uint
function public.count_form_tasks(context, train_template_id)
    assert(context, "context is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_form(),
        match_train_template_id(train_template_id)
    )

    return #filtered
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint|nil
---@return uint
function public.count_active_form_tasks(context, train_template_id)
    assert(context, "context is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_form(),
        match_train_template_id(train_template_id),
        match_not(
            match_state(TrainFormTask.defines.state.completed)
        )
    )

    return #filtered
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_disband_tasks(context, train_template_id)
    assert(context, "context is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_disband(),
        match_train_template_id(train_template_id)
    )

    return #filtered
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_active_disband_tasks(context, train_template_id)
    assert(context, "context is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_disband(),
        match_train_template_id(train_template_id),
        match_not(
            match_state(TrainDisbandTask.defines.state.completed)
        )
    )

    return #filtered
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_active_tasks(context, train_template_id)
    assert(context, "context is nil")

    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_train_template_id(train_template_id),
        match_not(
            match_state(TrainDisbandTask.defines.state.completed)
        )
    )

    return #filtered
end

function public.total_count_tasks()
    local filtered = rows(
        match_not_deleted()
    )

    return #filtered
end

function public.total_count_form_tasks()
    return #rows(match_not_deleted(), match_type_form())
end

---@return scripts.lib.domain.entity.task.TrainFormTask[]|scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_all_tasks()
    local filtered = rows(
        match_not_deleted()
    )

    return hydrate(filtered)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return scripts.lib.domain.entity.task.TrainFormTask[]|scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_template_tasks(context, train_template_id)
    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_train_template_id(train_template_id)
    )

    return hydrate(filtered)
end

---@param context scripts.lib.domain.Context|nil
function public.find_form_tasks_ready_for_deploy(context)
    local filtered = rows(
        match_not_deleted(),
        match_context(context),
        match_type_form(),
        match_state(
            TrainFormTask.defines.state.formed,
            TrainFormTask.defines.state.deploy
        )
    )

    return hydrate(filtered)
end

function public.count_form_tasks_ready_for_deploy()
    local filtered = rows(
        match_not_deleted(),
        match_type_form(),
        match_state(TrainFormTask.defines.state.formed, TrainFormTask.defines.state.deploy)
    )

    return #filtered
end

---@param context scripts.lib.domain.Context
function public.has_tasks(context)
    return #rows(match_context(context))
end

return public