local automated_train_depot_building = table.deepcopy(data.raw["container"]["steel-chest"])
automated_train_depot_building.name = "automated-train-depot-building"

local automated_train_depot_building_input = table.deepcopy(data.raw["lamp"]["small-lamp"])
automated_train_depot_building_input.name = "automated-train-depot-building-input"
--automated_train_depot_building_input.flags = {"hidden"}

local automated_train_depot_building_output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
automated_train_depot_building_output.name = "automated-train-depot-building-output"
--automated_train_depot_building_output.flags = {"hidden"}

local automated_train_depot_building_inventory_left_input = table.deepcopy(data.raw["container"]["steel-chest"])
automated_train_depot_building_inventory_left_input.name = "automated-train-depot-building-inventory-left-input"
--automated_train_depot_building_inventory_left_input.flags = {"hidden"}

local automated_train_depot_building_inventory_right_input = table.deepcopy(data.raw["container"]["steel-chest"])
automated_train_depot_building_inventory_right_input.name = "automated-train-depot-building-inventory-right-input"
--automated_train_depot_building_inventory_right_input.flags = {"hidden"}

data:extend({
    automated_train_depot_building,
    automated_train_depot_building_input,
    automated_train_depot_building_output,
    automated_train_depot_building_inventory_left_input,
    automated_train_depot_building_inventory_right_input,
})