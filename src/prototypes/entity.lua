local prototype_defines = require("defines.index")

---@param selection_box BoundingBox
---@return BoundingBox
local function selection_box_to_collision_box(selection_box)
    return {
        left_top = {
            x = selection_box.left_top.x + 0.01,
            y = selection_box.left_top.y + 0.01
        },
        right_bottom = {
            x = selection_box.right_bottom.x - 0.01,
            y = selection_box.right_bottom.y - 0.01
        }
    }
end

---@param prototype LuaEntityPrototype
local function configure_depot_part_prototype(prototype)
    local empty_box = {{0, 0}, {0, 0}}

    prototype.selectable_in_game = false
    prototype.minable = nil
    prototype.selection_priority = 1
    prototype.collision_box = empty_box
    prototype.selection_box = empty_box
    prototype.collision_mask = nil
    prototype.flags = {
        "hidden",
        "hide-alt-info",
        "not-selectable-in-game",
        "not-in-kill-statistics",
        "not-deconstructable",
        "not-blueprintable",
    }
end

local prototypes = {}

------------- PROTOTYPE

local depot_size = { x = 9, y = 9}

local prototype = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
prototype.tile_width = 2
prototype.tile_height = 2
prototype.name = prototype_defines.entity.depot_building.name
prototype.selectable_in_game = true
prototype.selection_priority = 51
prototype.selection_box = { left_top = { x = -1 * depot_size.x, y = -1 * depot_size.y}, right_bottom = { x = depot_size.x, y = depot_size.y }}
prototype.collision_box = selection_box_to_collision_box(prototype.selection_box)
prototype.minable = { mining_time = 1, result = prototype_defines.item.depot_building }
prototype.create_ghost_on_death = true -- todo not work
--entity.icon = nil todo check
--entity.icon_size = nil todo check
--entity.icons = nil todo check
--entity.icon_mipmaps = nil todo check

table.insert(prototypes, prototype)

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["rail-signal"]["rail-signal"])
prototype.name = prototype_defines.entity.depot_building.parts.rail_signal
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["rail-chain-signal"]["rail-chain-signal"])
prototype.name = prototype_defines.entity.depot_building.parts.rail_chain_signal
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["train-stop"]["train-stop"])
prototype.name = prototype_defines.entity.depot_building.parts.train_stop_input
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["train-stop"]["train-stop"])
prototype.name = prototype_defines.entity.depot_building.parts.train_stop_output
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = table.deepcopy(data.raw["character"]["character"])
prototype.name = prototype_defines.entity.depot_driver
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = table.deepcopy(data.raw["straight-rail"]["straight-rail"])
prototype.name = prototype_defines.entity.depot_building.parts.straight_rail
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = table.deepcopy(data.raw["locomotive"]["locomotive"])
prototype.name = prototype_defines.entity.depot_locomotive
prototype.selectable_in_game = false
prototype.minable = nil
prototype.selection_priority = 1
prototype.collision_mask = nil
prototype.flags = {
    "hidden",
    "hide-alt-info",
    "not-selectable-in-game",
    "not-in-kill-statistics",
    "not-deconstructable",
    "not-blueprintable",
}
table.insert(prototypes, prototype)

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["container"]["steel-chest"])
prototype.enable_inventory_bar = false
prototype.inventory_size = 192
prototype.tile_width = 2
prototype.tile_height = 2
prototype.name = prototype_defines.entity.depot_building.parts.storage
prototype.selectable_in_game = true
prototype.selection_priority = 51
prototype.selection_box = { left_top = { x = -1 * depot_size.y, y = -1 * depot_size.x}, right_bottom = { x = depot_size.y, y = depot_size.x}}
prototype.collision_box = selection_box_to_collision_box(prototype.selection_box)
prototype.minable = { mining_time = 1, result = prototype_defines.item.depot_building }
prototype.create_ghost_on_death = true -- todo not work
--entity.icon = nil todo check
--entity.icon_size = nil todo check
--entity.icons = nil todo check
--entity.icon_mipmaps = nil todo check

table.insert(prototypes, prototype)

data:extend(prototypes)