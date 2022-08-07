local mod = {}

mod.defines = require("scripts.defines")

-- global table for runtime data
mod.global = {
    frames = {},
    frames_stack = {},
}

return mod