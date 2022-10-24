local flib_table = require("__flib__.table")

local logger = require("scripts.lib.logger")
local TrainFormingTask = require("scripts.lib.domain.entity.task.TrainFormingTask")
local TrainDisbandTask = require("scripts.lib.domain.entity.task.TrainDisbandTask")
local Sequence = require("scripts.lib.Sequence")
local garbage_collector = require("scripts.persistence.garbage_collector")

local public = {}
local private = {}

---@type scripts.lib.Sequence
local train_task_sequence

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---@param v table
---@param context scripts.lib.domain.Context
function private.match_context(v, context)
    if context == nil then
        return true
    end

    return context:is_same(v.surface_name, v.force_name)
end

---@param v table
---@param type string
function private.match_type(v, type)
    if type == nil then
        return true
    end

    return v.type == type
end

---@param v table
---@param train_template_id uint
function private.match_train_template_id(v, train_template_id)
    if train_template_id == nil then
        return true
    end

    return v.train_template_id == train_template_id
end

---@param v table
---@param state string
function private.match_state(v, state)
    if state == nil then
        return true
    end

    if type(state) == "string" then
        return v.state == state
    elseif type(state) == "table" then
        return flib_table.find(state, v.state) ~= nil
    end

    return v.state == state
end

---@param context scripts.lib.domain.Context
---@param type string
---@param train_template_id uint
---@param state table|string
function private.find_trains_tasks(context, type, train_template_id, state)
    ---@param v scripts.lib.domain.entity.task.TrainDisbandTask|scripts.lib.domain.entity.task.TrainDisbandTask
    local rows = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and
                private.match_type(v, type) and
                private.match_context(v, context) and
                private.match_train_template_id(v, train_template_id) and
                private.match_state(v, state)
    end, true)

    return rows
end

---@param task_data table
---@return scripts.lib.domain.entity.task.TrainDisbandTask|scripts.lib.domain.entity.task.TrainFormingTask|nil
function private.hydrate_task(task_data)
    if task_data.type == TrainFormingTask.type then
        return TrainFormingTask.from_table(task_data)
    end

    if task_data.type == TrainDisbandTask.type then
        return TrainDisbandTask.from_table(task_data)
    end

    return nil
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

---@param train_task scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
---@return scripts.lib.domain.entity.task.TrainFormingTask|scripts.lib.domain.entity.task.TrainDisbandTask
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
---@return scripts.lib.domain.entity.task.TrainFormingTask[]
function public.find_forming_tasks(context, train_template_id)
    assert(context, "context is nil")

    local rows = private.find_trains_tasks(context, TrainFormingTask.defines.type, train_template_id, nil)

    return flib_table.map(rows, private.hydrate_task)
end

---@param train_template_id uint
---@param context scripts.lib.domain.Context
---@return scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_disbanding_tasks(context, train_template_id)
    assert(context, "context is nil")

    local rows = private.find_trains_tasks(context, TrainDisbandTask.defines.type, train_template_id, nil)

    return flib_table.map(rows, private.hydrate_task)
end

function public.count_deploying_tasks(context)
    assert(context, "context is nil")

    local rows = private.find_trains_tasks(
            context,
            TrainFormingTask.defines.type,
            nil,
            TrainFormingTask.defines.state.deploy
    )

    return #rows
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_forming_tasks(context, train_template_id)
    assert(context, "context is nil")

    local tasks = private.find_trains_tasks(
            context,
            TrainFormingTask.defines.type,
            train_template_id,
            nil
    )

    return #tasks
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return uint
function public.count_disband_tasks(context, train_template_id)
    assert(context, "context is nil")

    local tasks = private.find_trains_tasks(
            context,
            TrainDisbandTask.defines.type,
            train_template_id,
            nil
    )

    return #tasks
end

function public.total_count_forming_tasks()
    local tasks = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and
                v.type == TrainFormingTask.defines.type
    end, true)

    return #tasks
end

---@return scripts.lib.domain.entity.task.TrainFormingTask[]|scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_all_tasks()
    local rows = flib_table.filter(global.trains_tasks, function(v) return v.deleted == false end, true)

    return flib_table.map(rows, private.hydrate_task)
end

---@param context scripts.lib.domain.Context
---@param train_template_id uint
---@return scripts.lib.domain.entity.task.TrainFormingTask[]|scripts.lib.domain.entity.task.TrainDisbandTask[]
function public.find_all_tasks_for_template(context, train_template_id)
    local rows = private.find_trains_tasks(context, nil, train_template_id, nil)

    return flib_table.map(rows, private.hydrate_task)
end

---@return uint
function public.find_all_disbanding_tasks()
    local rows = flib_table.filter(global.trains_tasks, function(v)
        return v.deleted == false and v.type == TrainDisbandTask.defines.type
    end, true)

    return flib_table.map(rows, private.hydrate_task)
end

---@param context scripts.lib.domain.Context|nil
function public.find_forming_tasks_ready_for_deploy(context)
    local rows = private.find_trains_tasks(
            context,
            TrainFormingTask.type,
            nil,
            {TrainFormingTask.defines.state.formed, TrainFormingTask.defines.state.deploy}
    )

    return flib_table.map(rows, private.hydrate_task)
end

function public.count_forming_tasks_ready_for_deploy()
    local rows = private.find_trains_tasks(
            nil,
            TrainFormingTask.type,
            nil,
            {TrainFormingTask.defines.state.formed, TrainFormingTask.defines.state.deploy}
    )

    return #rows
end

---@param context scripts.lib.domain.Context
function public.has_tasks(context)
    return #private.find_trains_tasks(context) > 0
end

return public