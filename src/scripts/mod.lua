local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.lib.logger")

-- global table for runtime data
mod.global = {
    frames = {},
    frames_stack = {},
}

return mod