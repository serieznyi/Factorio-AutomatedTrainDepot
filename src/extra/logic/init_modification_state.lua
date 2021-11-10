local Configuration = require("extra.lib.Configuration")
local Logger = require("extra.lib.Logger")

local modification_state = {}

modification_state.constants = require("extra.constants")

modification_state.settings = Configuration()

modification_state.registered_depots = {}

modification_state.logger = Logger()

return modification_state