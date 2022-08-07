local console = {}

-- todo rewrite

local LEVEL = {
    NONE = 1,
    WARNING = 2,
    INFO = 3,
    DEBUG = 4,
}
local DEFAULT_LEVEL = LEVEL.WARNING

---@param level int
---@param text string
local function write_message(level, text)
    if level <= global.console.level then
        -- todo write message for all or for concretter player
        local first_player = game.get_player(1)
        first_player.print(text)
    end
end

---@param player_index int
function console.load(player_index)
    local player = game.get_player(player_index)
    local settings = settings.get_player_settings(player)

    global.console = {
        level = tonumber(settings["atd-console-level"].value)
    }
end

function console.init()
    global.console = {
        level = DEFAULT_LEVEL
    }
end

---@param text string
function console.warning(text)
    write_message(LEVEL.WARNING, text)
end

---@param text string
function console.info(text)
    write_message(LEVEL.INFO, text)
end

---@param text string
function console.debug(text)
    write_message(LEVEL.DEBUG, text)
end

return console