local prototype_defines = require("defines.index")

local automated_train_depot = {
    type = "technology",
    name = prototype_defines.technology.automated_train_depot,
    icon = "__AutomatedTrainDepot__/graphics/technology/automated-train-depot.png",
    icon_size = 256,
    --icon_mipmaps = 4, todo use mipmaps
    effects = {
        {
            type = "unlock-recipe",
            recipe = prototype_defines.recipe.depot_building,
        }
    },
    prerequisites = { -- todo need balance
        "rail-signals",
        "fast-inserter",
        "gate",
        "concrete",
    },
    unit = {
        count = 1000, -- todo need balance
        ingredients =
        {
            {"logistic-science-pack", 1},
            {"automation-science-pack", 1},
            {"production-science-pack", 1},
        },
        time = 30 -- todo need balance
    },
    --order = "g-e-d" todo how it work?
}

data:extend({ automated_train_depot })