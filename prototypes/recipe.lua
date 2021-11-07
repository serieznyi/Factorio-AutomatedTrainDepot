local train_depot = {
    type = "recipe",
    name = "automated-train-depot-building",
    enabled = false,
    ingredients = { -- todo balance it
        {"concrete", 1000},
        {"steel-plate", 500},
        {"rail-signal", 20},
        {"construction-robot", 50},
        {"roboport", 1},
        {"gate", 6},
    },
    result = "automated-train-depot-building"
}

data:extend({ train_depot })