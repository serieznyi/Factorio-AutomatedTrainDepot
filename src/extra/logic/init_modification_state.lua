local Configuration = require("extra.lib.Configuration")

local modification_state = {}

modification_state.constants = require("extra.constants")

modification_state.settings = Configuration()

modification_state.registered_depots = {}

return modification_state