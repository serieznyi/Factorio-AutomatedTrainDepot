local LEVEL = {
    NONE = 0,
    WARNING = 1,
    INFO = 2,
    DEBUG = 3,
}

-- @module extra.lib.Console
local Console = {
    level = LEVEL.WARNING
}

---@param self table
---@param level int
---@param text string
local function write_message(self, level, text)
    if level <= self.level then
        local first_player = game.get_player(1)
        first_player.print(text)
    end
end

---@param text string
function Console:warning(text)
    write_message(self, LEVEL.WARNING, text)
end

---@param text string
function Console:info(text)
    write_message(self, LEVEL.INFO, text)
end

---@param text string
function Console:debug(text)
    write_message(self, LEVEL.DEBUG, text)
end

setmetatable(Console, {
    --- @param _ table
    --- @param level int  Value between 0 and 3 included
    __call = function(_, level)
        local self = {}
        setmetatable(self, { __index = Console })

        if level ~= nil then
            self.level = level
        end

        return self
    end
})

return Console