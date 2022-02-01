local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.logger")
mod.console = require("scripts.console")

-- todo use global util instead require
mod.util = {
    table = require("scripts.util.table"),
    event = require("scripts.util.event"),
    gui = require("scripts.util.gui"),
    game = require("scripts.util.game"),
}

mod.depots = {} -- todo remove me

return mod