local logger = require("scripts.lib.logger")
local persistence_storage = require("scripts.persistence.persistence_storage")
local Context = require("scripts.lib.domain.Context")

local Notifier = {}

---@param force LuaForce
---@param message LocalisedString
---@param play_sound bool Default - true
function Notifier.error(force, message, play_sound)
    play_sound = play_sound ~= nil and play_sound or true

    if play_sound then
        -- todo play error sound
        --force.play_sound{path = ""}
    end

    force.print(message, {1, 0, 0})
end

return Notifier