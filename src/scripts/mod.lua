local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.lib.service.Logger")
mod.console = require("scripts.console")

-- todo use global util instead require
mod.util = {
    table = require("scripts.util.table"),
    gui = require("scripts.util.gui"),
}

-- global table for runtime data
mod.global = {
    frames = {},
    frames_stack = {},
}

return mod