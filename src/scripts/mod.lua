local atd = {}

atd.defines = require("scripts.defines")

-- global table for runtime data
atd.global = {
    frames = {},
    frames_stack = {},
}

return atd