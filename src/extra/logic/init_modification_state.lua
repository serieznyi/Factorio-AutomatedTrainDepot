local Configuration = require("extra.lib.Configuration")
local Logger = require("extra.lib.Logger")
local Console = require("extra.lib.Console")

local automated_train_depot = {}

automated_train_depot.constants = require("extra.constants")

automated_train_depot.settings = Configuration()

automated_train_depot.logger = Logger()
automated_train_depot.console = Console(3) -- TODO

automated_train_depot.depots = {}

return automated_train_depot