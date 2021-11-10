local enum = require('enum')

---@type
local Level = enum {
    DEBUG,
    INFO,
    WARNING,
    ERROR,
}

-- @module extra.lib.Logger
local Logger = {
}

local function write_message(level, text)
    --    TODO
end

function Logger:error(text)
    self:_(Level.ERROR, text)
end

function Logger:warning(text)
    self:_(Level.WARNING, text)
end

function Logger:info(text)
    self:_(Level.INFO, text)
end

function Logger:debug(text)
    self:_(Level.DEBUG, text)
end

local metatable = {
    __call = function()
        local self = {}
        setmetatable(self, { __index = Logger })
        return self
    end
}
setmetatable(Logger, metatable)

return Logger