local flib_table = require("__flib__.table")

local frame_stack = {}

---@return table
function frame_stack.all()
    return flib_table.array_copy(atd.global.frames_stack)
end

---@param frame gui.frame.Frame
function frame_stack.frame_stack_push(frame)
    if frame_stack.exists(frame) then
        return
    end

    table.insert(atd.global.frames_stack, frame)
end

---@param frame gui.frame.Frame
---@return bool
function frame_stack.exists(frame)
    ---@param frame_in_stack gui.frame.Frame
    for _, frame_in_stack in ipairs(atd.global.frames_stack) do
        if frame_in_stack.name == frame.name then
            return true
        end
    end

    return false
end

---@return bool
function frame_stack.empty()
    return #atd.global.frames_stack == 0
end

---@return gui.frame.Frame
function frame_stack.frame_stack_pop()
    if #atd.global.frames_stack == 0 then
        return
    end

    return table.remove(atd.global.frames_stack)
end

---@return gui.frame.Frame
function frame_stack.frame_stack_last()
    if #atd.global.frames_stack == 0 then
        return
    end

    local last_index = #atd.global.frames_stack;

    return atd.global.frames_stack[last_index]
end

return frame_stack