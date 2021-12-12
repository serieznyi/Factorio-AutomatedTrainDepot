-- @module lib.Configuration
local Configuration = {
    ---@type int chat_logging_level
    chat_logging_level = nil,
}

function Configuration:refresh()
    self.chat_logging_level = tonumber(settings.global["automated-train-depot-console-level"].value)
end

setmetatable(Configuration, {
    ---@param _ table
    __call = function(_)
        local self = {}
        setmetatable(self, { __index = Configuration })

        return self
    end
})

return Configuration