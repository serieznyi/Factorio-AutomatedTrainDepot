-- @module lib.Configuration
local Configuration = {
    chat_logging_level = nil,
}

function Configuration:refresh()
    self.chat_logging_level = tonumber(settings.global["automated-train-depot-console-level"].value)
end

setmetatable(Configuration, {
    ---@param self table
    __call = function(self)
        return self
    end
})

return Configuration