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

mod.global = {
    frames_stack = {}
}

return mod