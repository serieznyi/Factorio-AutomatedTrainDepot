local Configuration = require("extra.lib.Configuration")
local Logger = require("extra.lib.Logger")

local automated_train_depot = {}

automated_train_depot.constants = require("extra.constants")

automated_train_depot.settings = Configuration()

automated_train_depot.registered_depots = {
    depot_frame = nil
}

automated_train_depot.logger = Logger()

return automated_train_depot