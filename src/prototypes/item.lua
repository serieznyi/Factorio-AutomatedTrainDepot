local atd_building = {
    type = "item",
    subgroup = "train-transport",
    name = "automated-train-depot-building",
    icon = "__AutomatedTrainDepot__/media/graphics/item/automated-train-depot-building.png",
    icon_size = 64,
    stack_size = 1,
    --icon_mipmaps = 4, todo use mipmaps
    --order = "g-e-d" todo how it work?
    place_result = "automated-train-depot-building",
    flags = {"primary-place-result"},
    default_request_amount = 1,
}

data:extend({
    atd_building,
})