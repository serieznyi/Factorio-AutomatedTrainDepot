local prototype_defines = require("defines.index")

local train_depot = {
    type = "recipe",
    category = "advanced-crafting",
    subgroup = "train-transport",
    name = prototype_defines.recipe.depot_building,
    enabled = false,
    ingredients = { -- todo balance it
        {"concrete", 1000},
        {"steel-plate", 500},
        {"train-stop", 10},
        {"rail", 300},
        {"rail-signal", 20},
        {"logistic-chest-requester", 1},
        {"logistic-chest-active-provider", 1},
        {"filter-inserter", 50},
    },
    result = prototype_defines.item.depot_building,
    result_count = 1,
}

local depot_working_imitation_recipe = {
    type = "recipe",
    name = prototype_defines.recipe.depot_working_imitation,
    enabled = true,
    unlock_results = false,
    hidden = true,
    hide_from_stats = true,
    hide_from_player_crafting = true,
    ingredients = {},
    result = "locomotive",
    energy_required = 99999999,
    module_specification = {
        module_slots = 6
    },
}

data:extend({ train_depot, depot_working_imitation_recipe })