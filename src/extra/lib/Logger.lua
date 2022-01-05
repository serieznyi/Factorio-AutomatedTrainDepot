local misc = require("__flib__.misc")

local LEVEL = {
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR",
}

---------------------------------------------------
--  Pattern parts:
--   - %date
--   - %level
--   - %message
--   - %category
---------------------------------------------------
local DEFAULT_PATTERN = "[%date][%level][%category] %message"

-- @module extra.lib.Logger
local Logger = {
    message_pattern = DEFAULT_PATTERN
}

---@param level string
---@param text string
local function write_message(level, category, text)
    local message = Logger.message_pattern

    message = string.gsub(message,"%%date", misc.ticks_to_timestring(game.ticks_played))
    message = string.gsub(message,"%%level", tostring(level))
    message = string.gsub(message,"%%message", tostring(text))
    message = string.gsub(message,"%%category", tostring(category or 'default'))

    log(message)
end

---@param text string
---@param[opt=default] category Message category
function Logger:error(text, category)
    write_message(LEVEL.ERROR, category, text)
end

---@param text string
---@param[opt=default] category Message category
function Logger:warning(text, category)
    write_message(LEVEL.WARNING, category, text)
end

---@param text string
---@param[opt=default] category Message category
function Logger:info(text, category)
    write_message(LEVEL.INFO, category, text)
end

---@param text string
---@param[opt=default] category Message category
function Logger:debug(text, category)
    write_message(LEVEL.DEBUG, category, text)
end

setmetatable(Logger, {
    --- @param _ table
    --- @param message_pattern string
    __call = function(_, message_pattern)
        local self = {}
        setmetatable(self, { __index = Logger })

        if message_pattern ~= nil and message_pattern ~= "" then
            self.message_pattern = message_pattern
        end

        return self
    end
})

return Logger