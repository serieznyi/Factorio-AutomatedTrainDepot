local misc = require("__flib__.misc")

---@type
local LEVEL = {
    DEBUG = "DEBUG",
    INFO = "INFO",
    WARNING = "WARNING",
    ERROR = "ERROR",
}

-- @module extra.lib.Logger
---------------------------------------------------
--  Pattern parts:
--   - %date
--   - %level
--   - %message
---------------------------------------------------

local DEFAULT_PATTERN = "[%date][%level] %message"

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

local metatable = {
    __call = function(message_pattern)
        local self = {}
        setmetatable(self, { __index = Logger })

        if message_pattern ~= nil then
            self.message_pattern = message_pattern
        end

        return self
    end
}
setmetatable(Logger, metatable)

return Logger