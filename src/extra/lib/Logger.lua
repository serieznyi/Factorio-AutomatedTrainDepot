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
---------------------------------------------------
local DEFAULT_PATTERN = "[%date][%level] %message"

-- @module extra.lib.Logger
local Logger = {
    message_pattern = DEFAULT_PATTERN
}

---@param level string
---@param text string
local function write_message(level, text)
    local message = Logger.message_pattern

    message = string.gsub(message,"%%date", misc.ticks_to_timestring(game.ticks_played))
    message = string.gsub(message,"%%level", tostring(level))
    message = string.gsub(message,"%%message", tostring(text))

    log(message)
end

---@param text string
function Logger:error(text)
    write_message(LEVEL.ERROR, text)
end

---@param text string
function Logger:warning(text)
    write_message(LEVEL.WARNING, text)
end

---@param text string
function Logger:info(text)
    write_message(LEVEL.INFO, text)
end

---@param text string
function Logger:debug(text)
    write_message(LEVEL.DEBUG, text)
end

setmetatable(Logger, {
    --- @param self table
    --- @param message_pattern string
    __call = function(self, message_pattern)
        if message_pattern ~= nil and message_pattern ~= "" then
            self.message_pattern = message_pattern
        end

        return self
    end
})

return Logger