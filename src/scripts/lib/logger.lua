local flib_misc = require("__flib__.misc")

local util_table = require("scripts.util.table")

local logger = {}

local LEVEL = {
    WARNING = "warning",
    ERROR = "error",
    INFO = "info",
    DEBUG = "debug",
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
---@param category string
---@param text string
---@param args table
local function write_message(level, category, text, args)
    local message = PATTERN

    if type(text) == "table" then
        text = util_table.to_string(text)
    end

    message = string.gsub(message,"%%date", game ~= nil and flib_misc.ticks_to_timestring(game.ticks_played) or 0)
    message = string.gsub(message,"%%level", tostring(level))
    message = string.gsub(message,"%%message", tostring(text))
    message = string.gsub(message,"%%category", tostring(category or 'default'))

    for i, v in ipairs(args or {}) do
        message = string.gsub(message,"{" .. tostring(i) .. "}", tostring(v))
    end

    log(message)
end

---@param text string
---@param args table
---@param category string Message category
function logger.error(text, args, category)
    write_message(LEVEL.ERROR, category, text, args)
end

---@param text string
---@param args table
---@param category string Message category
function logger.warning(text, args, category)
    write_message(LEVEL.WARNING, category, text, args)
end

---@param text string
---@param args table
---@param category string Message category
function logger.info(text, args, category)
    write_message(LEVEL.INFO, category, text, args)
end

---@param text string|table
---@param args table
---@param category string Message category
function logger.debug(text, args, category)
    write_message(LEVEL.DEBUG, category, text, args)
end

return logger