local chat = {}

local Level = {
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
}

function Chat:new()
    local self = {}
    setmetatable(self, { __index = Logger })
    return self
end

local function sendMessage(level, text)
    local first_player = game.get_player(1)
    first_player.print(first_player.name)

    --    TODO
end

function Chat:error(text)
    self:sendMessage(Level.ERROR, text)
end

function Chat:warning(text)
    self:sendMessage(Level.WARNING, text)
end

function Chat:info(text)
    self:sendMessage(Level.INFO, text)
end

return chat