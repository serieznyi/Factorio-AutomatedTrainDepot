--- @module scripts.lib.Sequence
local Sequence = {
    value = 1,
}

---@return uint
function Sequence:next()
    self.value = self.value + 1

    return self.value - 1
end

function Sequence:reset()
    self.value = 1
end

setmetatable(Sequence, {
    --- @param _ table
    --- @param init_value uint
    __call = function(_, init_value)
        local self = {}
        setmetatable(self, { __index = Sequence })

        if init_value ~= nil then
            self.value = init_value
        end

        return self
    end
})

return Sequence