local entity = require("defines.entity")

local flags = {
    "hidden",
    "hide-alt-info",
    "not-selectable-in-game",
    "not-in-kill-statistics",
    "not-deconstructable",
    "not-blueprintable",
}

local empty_sprite =
{
    filename = "__core__/graphics/empty.png",
    width = 1,
    height = 1,
    frame_count = 1
}
local empty_collision_box = {{0, 0}, {0, 0}}

local automated_train_depot_building = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
automated_train_depot_building.tile_width = 2
automated_train_depot_building.tile_height = 2
automated_train_depot_building.name = entity.depot_building.name
automated_train_depot_building.selectable_in_game = true
local selection_box = { x1 = -7, y1 = -8.5, x2 = 7, y2 = 7.0}
automated_train_depot_building.selection_box = { { selection_box.x1, selection_box.y1},
                                                 { selection_box.x2, selection_box.y2}}
automated_train_depot_building.collision_box = { { selection_box.x1 + 0.01, selection_box.y1 + 0.01},
                                                 { selection_box.x2 - 0.01, selection_box.y2 - 0.01}}
automated_train_depot_building.minable = {mining_time = 1, result = "atd-building"}
automated_train_depot_building.create_ghost_on_death = true

--automated_train_depot_building.icon = nil todo check
--automated_train_depot_building.icon_size = nil todo check
--automated_train_depot_building.icons = nil todo check
--automated_train_depot_building.icon_mipmaps = nil todo check

local automated_train_depot_building_input = table.deepcopy(data.raw["lamp"]["small-lamp"])
automated_train_depot_building_input.name = entity.depot_building_input.name
automated_train_depot_building_input.flags = flags
automated_train_depot_building_input.collision_mask = {}
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_building_output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
automated_train_depot_building_output.name = entity.depot_building_output.name
automated_train_depot_building_output.flags = flags
automated_train_depot_building_input.collision_mask = {}
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_building_train_stop_input = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_input.name = entity.depot_building_train_stop_input.name
automated_train_depot_building_train_stop_input.flags = flags
automated_train_depot_building_input.collision_mask = {}
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_building_train_stop_output = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_output.name = entity.depot_building_train_stop_output.name
automated_train_depot_building_train_stop_output.flags = flags
automated_train_depot_building_input.collision_mask = {}
automated_train_depot_building_input.collision_box = empty_collision_box

data:extend({
    automated_train_depot_building,
    automated_train_depot_building_input,
    automated_train_depot_building_output,
    automated_train_depot_building_train_stop_input,
    automated_train_depot_building_train_stop_output,
})