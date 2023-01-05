local atd = {}

atd.defines = require("scripts.defines")

-- global table for runtime data
atd.global = {
    -- Contains all opened player frames
    frames = {},
    -- Stack of opened frames
    frames_stack = {},
}

return atd