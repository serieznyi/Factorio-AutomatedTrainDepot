local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.logger")
mod.console = require("scripts.console")

-- todo use global util instead require
mod.util = {
    table = require("scripts.util.table"),
    gui = require("scripts.util.gui"),
    game = require("scripts.util.game"),
}

-- global table for runtime data
mod.global = {}

return mod