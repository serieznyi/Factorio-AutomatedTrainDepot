local prototype_defines = require("defines.index")

local base_technology_unit_count = 1000
local max_additional_slots_count = 3

local ingredients = {
    {"logistic-science-pack", 1},
    {"automation-science-pack", 1},
    {"production-science-pack", 1},
    {"utility-science-pack", 1},
}

local automated_train_depot = {
    type = "technology",
    name = "automated-train-depot-technology",
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
        "concrete",
        "logistic-system",
    },
    unit = {
        count = base_technology_unit_count,
        ingredients = ingredients,
        time = 30
    },
}

local atd_new_disband_slot = {
    type = "technology",
    name = "automated-train-depot-new-disband-slot-technology-1",
    icon = "__AutomatedTrainDepot__/graphics/technology/automated-train-depot.png",
    icon_size = 256,
    --icon_mipmaps = 4, todo use mipmaps
    effects = {},
    upgrade = true,
    max_level = max_additional_slots_count,
    prerequisites = { "automated-train-depot-technology" },
    unit = {
        count_formula = tostring(base_technology_unit_count) .. "+(L^2)*100",
        ingredients = ingredients,
        time = 30
    },
}

local atd_new_forming_slot = {
    type = "technology",
    name = "automated-train-depot-new-forming-slot-technology-1",
    icon = "__AutomatedTrainDepot__/graphics/technology/automated-train-depot.png",
    icon_size = 256,
    --icon_mipmaps = 4, todo use mipmaps
    effects = {},
    upgrade = true,
    max_level = max_additional_slots_count,
    prerequisites = { "automated-train-depot-technology" },
    unit = {
        count_formula = tostring(base_technology_unit_count) .. "+(L^2)*100",
        --count = base_technology_unit_count, -- todo replace
        ingredients = ingredients,
        time = 30
    },
}


data:extend({
    automated_train_depot,
    atd_new_disband_slot,
    atd_new_forming_slot,
})