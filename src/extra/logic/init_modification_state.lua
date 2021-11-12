local Configuration = require("extra.lib.Configuration")
local Logger = require("extra.lib.Logger")

local modification_state = {}

modification_state.constants = require("extra.constants")

modification_state.settings = Configuration()

modification_state.registered_depots = {
    depot_frame = nil
}

modification_state.logger = Logger()

return modification_state