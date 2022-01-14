local misc = require("__flib__.misc")

local logger = {}

local LEVEL = {
    NONE = 1,
    WARNING = 2,
    ERROR = 3,
    INFO = 4,
    DEBUG = 5,
}

---------------------------------------------------
--  Pattern parts:
--   - %date
--   - %level
--   - %message
--   - %category
---------------------------------------------------
local PATTERN = "[%date][%level][%category] %message"

---@param level string
---@param text string
local function write_message(level, category, text)
    local message = PATTERN

    message = string.gsub(message,"%%date", misc.ticks_to_timestring(game.ticks_played))
    message = string.gsub(message,"%%level", tostring(level))
    message = string.gsub(message,"%%message", tostring(text))
    message = string.gsub(message,"%%category", tostring(category or 'default'))

    log(message)
end

---@param text string
---@param[opt=default] category Message category
function logger.error(text, category)
    write_message(LEVEL.ERROR, category, text)
end

---@param text string
---@param[opt=default] category Message category
function logger.warning(text, category)
    write_message(LEVEL.WARNING, category, text)
end

---@param text string
---@param[opt=default] category Message category
function logger.info(text, category)
    write_message(LEVEL.INFO, category, text)
end

---@param text string
---@param[opt=default] category Message category
function logger.debug(text, category)
    write_message(LEVEL.DEBUG, category, text)
end

return logger