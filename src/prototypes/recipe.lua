local prototype_defines = require("defines.index")

local train_depot = {
    type = "recipe",
    category = "advanced-crafting",
    subgroup = "train-transport",
    name = prototype_defines.recipe.depot_building.name,
    enabled = false,
    ingredients = { -- todo balance it
        {"concrete", 1000},
        {"steel-plate", 500},
        {"train-stop", 10},
        {"rail", 300},
        {"rail-signal", 20},
        {"filter-inserter", 50},
        {"gate", 6},
    },
    result = prototype_defines.item.depot_building.name,
    result_count = 1,
}

data:extend({ train_depot })