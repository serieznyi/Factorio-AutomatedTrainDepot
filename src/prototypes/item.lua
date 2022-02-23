local prototype_defines = require("defines.index")

local atd_building_item = {
    type = "item",
    subgroup = "train-transport",
    name = prototype_defines.item.depot_building.name,
    icon = "__AutomatedTrainDepot__/media/graphics/item/automated-train-depot-building.png",
    icon_size = 64,
    stack_size = 1,
    --icon_mipmaps = 4, todo use mipmaps
    --order = "g-e-d" todo how it work?
    place_result = prototype_defines.entity.depot_building.name,
    flags = {"primary-place-result"},
    default_request_amount = 1,
}

data:extend({
    atd_building_item,
})