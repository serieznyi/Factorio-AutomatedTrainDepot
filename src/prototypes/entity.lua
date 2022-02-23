local prototype_defines = require("defines.index")

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
automated_train_depot_building.name = prototype_defines.entity.depot_building.name
automated_train_depot_building.selectable_in_game = true
local selection_box = { x1 = -7, y1 = -9, x2 = 7, y2 = 9 }
automated_train_depot_building.selection_box = { { selection_box.x1, selection_box.y1},
                                                 { selection_box.x2, selection_box.y2}}
automated_train_depot_building.collision_box = { { selection_box.x1 + 0.01, selection_box.y1 + 0.01},
                                                 { selection_box.x2 - 0.01, selection_box.y2 - 0.01}}
automated_train_depot_building.minable = {mining_time = 1, result = prototype_defines.item.depot_building.name }
automated_train_depot_building.create_ghost_on_death = true -- todo not work

--automated_train_depot_building.icon = nil todo check
--automated_train_depot_building.icon_size = nil todo check
--automated_train_depot_building.icons = nil todo check
--automated_train_depot_building.icon_mipmaps = nil todo check

local automated_train_depot_building_input = table.deepcopy(data.raw["lamp"]["small-lamp"])
automated_train_depot_building_input.name = prototype_defines.entity.depot_building_input.name
automated_train_depot_building_input.flags = flags
automated_train_depot_building_input.minable = nil
automated_train_depot_building_input.collision_mask = nil
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_straight_rail = table.deepcopy(data.raw["straight-rail"]["straight-rail"])
automated_train_depot_straight_rail.name = prototype_defines.entity.depot_building_straight_rail.name
automated_train_depot_straight_rail.flags = flags
automated_train_depot_straight_rail.minable = nil
automated_train_depot_straight_rail.collision_mask = nil
automated_train_depot_straight_rail.collision_box = empty_collision_box

local automated_train_depot_rail_signal = table.deepcopy(data.raw["rail-signal"]["rail-signal"])
automated_train_depot_rail_signal.name = prototype_defines.entity.depot_building_rail_signal.name
automated_train_depot_rail_signal.flags = flags
automated_train_depot_rail_signal.minable = nil
automated_train_depot_rail_signal.collision_mask = nil
automated_train_depot_rail_signal.collision_box = empty_collision_box

local automated_train_depot_building_output = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
automated_train_depot_building_output.name = prototype_defines.entity.depot_building_output.name
automated_train_depot_building_output.flags = flags
automated_train_depot_building_input.minable = nil
automated_train_depot_building_input.collision_mask = nil
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_building_train_stop_input = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_input.name = prototype_defines.entity.depot_building_train_stop_input.name
automated_train_depot_building_train_stop_input.flags = flags
automated_train_depot_building_input.minable = nil
automated_train_depot_building_input.collision_mask = nil
automated_train_depot_building_input.collision_box = empty_collision_box

local automated_train_depot_building_train_stop_output = table.deepcopy(data.raw["train-stop"]["train-stop"])
automated_train_depot_building_train_stop_output.name = prototype_defines.entity.depot_building_train_stop_output.name
automated_train_depot_building_train_stop_output.flags = flags
automated_train_depot_building_input.minable = nil
automated_train_depot_building_input.collision_mask = nil
automated_train_depot_building_input.collision_box = empty_collision_box

data:extend({
    automated_train_depot_building,
    automated_train_depot_building_input,
    automated_train_depot_building_output,
    automated_train_depot_building_train_stop_input,
    automated_train_depot_building_train_stop_output,
    automated_train_depot_straight_rail,
    automated_train_depot_rail_signal,
})