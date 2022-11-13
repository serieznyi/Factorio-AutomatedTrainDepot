return {
    entity = {
        depot_building = {
            name = "atd-building-entity",
            parts = {
                logistic_input = "atd-building-input-entity",
                logistic_output = "atd-building-output-entity",
                rail_signal = "atd-building-rail-signal-entity",
                rail_chain_signal = "atd-building-rail-chain-signal-entity",
                train_stop_input = "atd-building-train-stop-input-entity",
                train_stop_output = "atd-building-train-stop-output-entity",
                straight_rail = "atd-straight_rail",
                storage = "atd-depot-storage",
            }
        },
        depot_driver = "atd-depot-driver",
        depot_locomotive = "atd-depot-locomotive",
    },
    item = {
        depot_building = "atd-building-item",
    },
    recipe = {
        depot_building = "atd-building-recipe",
    },
    technology = {
        automated_train_depot = "automated-train-depot-technology",
    },
}