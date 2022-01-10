local Logger = require("lib.Logger")
local console = require("scripts.console")

local automated_train_depot = {}

automated_train_depot.constants = require("scripts.constants")

automated_train_depot.logger = Logger()
automated_train_depot.console = console

automated_train_depot.depots = {}

return automated_train_depot