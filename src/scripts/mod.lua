local mod = {}

mod.defines = require("scripts.defines")
mod.util = {
    table = require("scripts.util.table"),
    console = require("scripts.console"),
    logger = require("scripts.logger"),
}

mod.depots = {} -- todo remove me

return mod