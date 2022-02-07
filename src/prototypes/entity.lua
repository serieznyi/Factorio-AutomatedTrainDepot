local entity = require("defines.entity")

local automated_train_depot_building = table.deepcopy(data.raw["container"]["steel-chest"])
automated_train_depot_building.name = entity.depot_building.name
automated_train_depot_building.selection_box = {{-8.5, -6.5}, {9.5, 5.5}}
--automated_train_depot_building.collision_box = {{-8.4, -6.4}, {9.4, 5.4}}

local automated_train_depot_building_input = table.deepcopy(data.raw["lamp"]["small-lamp"])
automated_train_depot_building_input.name = entity.depot_building_input.name
--automated_train_depot_building_input.flags = {"hidden"} TODO make hidden

local automated_train_depot_building_output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
automated_train_depot_building_output.name = entity.depot_building_output.name
--automated_train_depot_building_output.flags = {"hidden"} TODO make hidden

local automated_train_depot_building_train_stop_input = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_input.name = entity.depot_building_train_stop_input.name
--automated_train_depot_building_output.flags = {"hidden"} TODO make hidden

local automated_train_depot_building_train_stop_output = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_output.name = entity.depot_building_train_stop_output.name
--automated_train_depot_building_output.flags = {"hidden"} TODO make hidden

local depot_train_driver = table.deepcopy(data.raw["character"]["character"])
depot_train_driver.name = "depot-train-driver"
depot_train_driver.collision_mask = { "ghost-layer"}

local depot_locomotive = table.deepcopy(data.raw["train"]["locomotive"])
depot_locomotive.name = "depot-locomotive"
depot_locomotive.collision_mask = { "ghost-layer"}

data:extend({
    automated_train_depot_building,
    automated_train_depot_building_input,
    automated_train_depot_building_output,
    automated_train_depot_building_train_stop_input,
    automated_train_depot_building_train_stop_output,
    depot_train_driver,
})