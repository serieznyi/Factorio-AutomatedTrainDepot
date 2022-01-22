local mod = {}

mod.defines = require("scripts.defines")
mod.util = {}
mod.util.table = require("scripts.util.table")
mod.util.console = require("scripts.console")
mod.util.logger = require("scripts.logger")

-- Save module runtime vars
mod.storage = {}
mod.depots = {}

return mod