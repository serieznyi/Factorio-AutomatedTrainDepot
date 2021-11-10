-- @module lib.Configuration
local Configuration = {
    chat_logging_level = nil,
}

function Configuration:refresh()
    self.chat_logging_level = tonumber(settings.global["automated-train-depot-console-level"].value)
end

local metatable = {
    __call = function()
        local self = {}
        setmetatable(self, { __index = Configuration })
        return self
    end
}
setmetatable(Configuration, metatable)

return Configuration