--- @module scripts.lib.Sequence
local Sequence = {
    value = 1,
    on_next_callback = function(value)  end,
}

---@return uint
function Sequence:next()
    self.value = self.value + 1
    self.on_next_callback(self.value)

    return self.value - 1
end

function Sequence:reset()
    self.value = 1
end

setmetatable(Sequence, {
    --- @param _ table
    --- @param init_value uint
    __call = function(_, init_value, on_next_callback)
        local self = {}
        setmetatable(self, { __index = Sequence })

        if init_value ~= nil then
            self.value = init_value
        end

        if on_next_callback ~= nil then
            self.on_next_callback = on_next_callback
        end

        return self
    end
})

return Sequence