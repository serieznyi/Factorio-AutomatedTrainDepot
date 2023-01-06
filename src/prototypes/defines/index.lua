return {
    entity = {
        depot_building = {
            name = "atd-building-entity",
            guideline = "atd-building-entity-fake",
            parts = {
                rail_signal = "atd-building-rail-signal-entity",
                rail_chain_signal = "atd-building-rail-chain-signal-entity",
                train_stop = "atd-train-stop-entity",
                straight_rail = "atd-straight_rail",
                storage_provider = "atd-depot-storage-provider",
                storage_requester = "atd-depot-storage-requester",
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