local mod = {}

mod.defines = require("scripts.defines")
mod.log = require("scripts.logger")
mod.console = require("scripts.console")

mod.util = {
    table = require("scripts.util.table"),
}

mod.depots = {} -- todo remove me

return mod