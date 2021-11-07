automated_train_depot = {}

automated_train_depot.name = "AutomatedTrainDepot"

---------------------------------------------------------------------------
-- -- -- Register prototypes
---------------------------------------------------------------------------

require ("prototypes.item")
require ("prototypes.entity")
require ("prototypes.recipe")
require ("prototypes.technology")

---------------------------------------------------------------------------
-- -- -- Compatibility initialization
---------------------------------------------------------------------------

require('compatibility.warn.0-data.index')

require('compatibility.apply.1-data.index')