local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.logger")
mod.console = require("scripts.console")
mod.dev_mode = true -- todo check var in CI

-- todo use global util instead require
mod.util = {
    table = require("scripts.util.table"),
    gui = require("scripts.util.gui"),
    game = require("scripts.util.game"),
}

-- global table for runtime data
mod.global = {
    frames = {},
    event_names = {},
}

return mod