local flib_gui = require("__flib__.gui")
local flib_table = require("__flib__.table")

local frame_stack = {}

---@return table
function frame_stack.all()
    return flib_table.array_copy(mod.global.frames_stack)
end

---@param frame gui.frame.Frame
function frame_stack.frame_stack_push(frame)
    if frame_stack.exists(frame) then
        return
    end

    table.insert(mod.global.frames_stack, frame)
end

---@param frame gui.frame.Frame
---@return bool
function frame_stack.exists(frame)
    ---@param frame_in_stack gui.frame.Frame
    for _, frame_in_stack in ipairs(mod.global.frames_stack) do
        if frame_in_stack.name == frame.name then
            return true
        end
    end

    return false
end

---@return bool
function frame_stack.empty()
    return #mod.global.frames_stack == 0
end

---@return gui.frame.Frame
function frame_stack.frame_stack_pop()
    if #mod.global.frames_stack == 0 then
        return
    end

    return table.remove(mod.global.frames_stack)
end

---@return gui.frame.Frame
function frame_stack.frame_stack_last()
    if #mod.global.frames_stack == 0 then
        return
    end

    local last_index = #mod.global.frames_stack;

    return mod.global.frames_stack[last_index]
end

return frame_stack