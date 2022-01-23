local mod = {}

mod.defines = require("scripts.defines")
mod.util = {
    table = require("scripts.util.table"),
    console = require("scripts.console"),
    logger = require("scripts.logger"),
}

-- Save module runtime vars
mod.storage = {
    gui = {},
    gui_component = {},
}
mod.depots = {} -- todo remove me

return mod