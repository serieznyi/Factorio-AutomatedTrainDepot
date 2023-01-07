local prototype_defines = require("defines.index")

local empty_box = {{0, 0}, {0, 0}}
local empty_icon_path = "__AutomatedTrainDepot__/graphics/entity/empty.png"
local empty_sprite = {
    filename = "__AutomatedTrainDepot__/graphics/entity/empty.png",
    priority = "high",
    width = 1,
    height = 1,
    scale = 0.5,
    shift = { 0, 0 },
}
local empty_animation = {
    north = {size = {1, 1}, filename = "__AutomatedTrainDepot__/graphics/entity/empty.png"},
    east = {size = {1, 1}, filename = "__AutomatedTrainDepot__/graphics/entity/empty.png"},
    south = {size = {1, 1}, filename = "__AutomatedTrainDepot__/graphics/entity/empty.png"},
    west = {size = {1, 1}, filename = "__AutomatedTrainDepot__/graphics/entity/empty.png"},
}
local inner_entity_flags = {
    "hidden",
    "hide-alt-info",
    "not-selectable-in-game",
    "not-in-kill-statistics",
    "not-deconstructable",
    "not-blueprintable",
}
local empty_rail_piece = {
    metals = { sheet = empty_sprite },
    backplates = { sheet = empty_sprite },
    ties = { sheet = empty_sprite },
    stone_path = { sheet = empty_sprite },
}
local empty_rail_pictures = {
    straight_rail_horizontal = empty_rail_piece,
    straight_rail_vertical = empty_rail_piece,
    straight_rail_diagonal_left_top = empty_rail_piece,
    straight_rail_diagonal_right_top = empty_rail_piece,
    straight_rail_diagonal_right_bottom = empty_rail_piece,
    straight_rail_diagonal_left_bottom = empty_rail_piece,
    curved_rail_vertical_left_top = empty_rail_piece,
    curved_rail_vertical_right_top = empty_rail_piece,
    curved_rail_vertical_right_bottom = empty_rail_piece,
    curved_rail_vertical_left_bottom = empty_rail_piece,
    curved_rail_horizontal_left_top = empty_rail_piece,
    curved_rail_horizontal_right_top = empty_rail_piece,
    curved_rail_horizontal_right_bottom = empty_rail_piece,
    curved_rail_horizontal_left_bottom = empty_rail_piece,
    rail_endings = {
        north = empty_sprite,
        north_east = empty_sprite,
        east = empty_sprite,
        south_east = empty_sprite,
        south = empty_sprite,
        south_west = empty_sprite,
        west = empty_sprite,
        north_west = empty_sprite,
        sheets = nil,
        sheet = nil,
    },
}

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

--------------- PROTOTYPE

local depot_size = { x = 7, y = 7}

local prototype = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
prototype.tile_width = 2
prototype.tile_height = 2
prototype.name = prototype_defines.entity.depot_building.guideline
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

------------- INNER ENTITY: RailSignal

prototype = table.deepcopy(data.raw["rail-signal"]["rail-signal"])
prototype.name = prototype_defines.entity.depot_building.parts.rail_signal
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- INNER ENTITY: RailChainSignal

prototype = table.deepcopy(data.raw["rail-chain-signal"]["rail-chain-signal"])
prototype.name = prototype_defines.entity.depot_building.parts.rail_chain_signal
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- INNER ENTITY: TrainStop

table.insert(prototypes, {
    type = "train-stop",
    name = prototype_defines.entity.depot_building.parts.train_stop,
    animation_ticks_per_frame = 1,
    flags = inner_entity_flags,
})

------------- PROTOTYPE

prototype = table.deepcopy(data.raw["character"]["character"])
prototype.name = prototype_defines.entity.depot_driver
configure_depot_part_prototype(prototype)
table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = table.deepcopy(data.raw["straight-rail"]["straight-rail"])
prototype.name = prototype_defines.entity.depot_building.parts.straight_rail
prototype.pictures = empty_rail_pictures
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

prototype = table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"])
prototype.name = prototype_defines.entity.depot_building.parts.storage_provider
prototype.inventory_size = 96
prototype.enable_inventory_bar = false
prototype.selectable_in_game = true
prototype.selection_priority = 52
prototype.minable = nil
prototype.create_ghost_on_death = false
prototype.selection_box = { left_top = { x = -1.5, y = -1.5}, right_bottom = { x = 1.5, y = 1.5 } }
prototype.collision_box = { left_top = { x = -1.5, y = -1.5}, right_bottom = { x = 1.5, y = 1.5 } }

table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
prototype.name = prototype_defines.entity.depot_building.parts.storage_requester
prototype.inventory_size = 96
prototype.enable_inventory_bar = true
prototype.selectable_in_game = true
prototype.selection_priority = 52
prototype.minable = nil
prototype.create_ghost_on_death = false
prototype.selection_box = { left_top = { x = -1.5, y = -1.5}, right_bottom = { x = 1.5, y = 1.5 } }
prototype.collision_box = { left_top = { x = -1.5, y = -1.5}, right_bottom = { x = 1.5, y = 1.5 } }

table.insert(prototypes, prototype)

------------- PROTOTYPE
prototype = {
    type = "module",
    icon = empty_icon_path,
    icon_size = 1,
    name = "atd-depot-module",
    stack_size = 1,
    flags = {"hidden"},
    category = "productivity",
    effect = {
        consumption = {
            bonus = 1.0
        }
    },
    tier = 1,
}

table.insert(prototypes, prototype)
------------- PROTOTYPE

local hit_effects = require("__base__/prototypes/entity/hit-effects")
local sounds = require("__base__/prototypes/entity/sounds")
local selection_box = { left_top = { x = -1 * depot_size.y, y = -1 * depot_size.x}, right_bottom = { x = depot_size.y, y = depot_size.x} }

prototype = {
    type = "assembling-machine",
    name = prototype_defines.entity.depot_building.name,
    icon_size = 64,
    icon_mipmaps = 4,
    icon = "__AutomatedTrainDepot__/graphics/icons/trash.png",
    flags = { "placeable-neutral", "placeable-player", "player-creation" },
    minable = { hardness = 1, mining_time = 1, result = prototype_defines.item.depot_building },
    max_health = 500,
    --corpse = "kr-big-random-pipes-remnant",
    dying_explosion = "big-explosion",
    damaged_trigger_effect = hit_effects.entity(),
    selection_priority = 51,
    resistances = {
        { type = "impact", percent = 50 },
    },
    --fluid_boxes = {
    --    {
    --        production_type = "input",
    --        pipe_picture = kr_pipe_path,
    --        pipe_covers = pipecoverspictures(),
    --        base_area = 10,
    --        height = 2,
    --        base_level = -1,
    --        pipe_connections = {
    --            { type = "input-output", position = { 0, -4 } },
    --            { type = "input-output", position = { 0, 4 } },
    --        },
    --    },
    --    {
    --        production_type = "input",
    --        pipe_picture = kr_pipe_path,
    --        pipe_covers = pipecoverspictures(),
    --        base_area = 10,
    --        base_level = -1,
    --        pipe_connections = {
    --            { type = "input-output", position = { 4, 0 } },
    --            { type = "input-output", position = { -4, 0 } },
    --        },
    --    },
    --    off_when_no_fluid_recipe = false,
    --},
    collision_box = selection_box_to_collision_box(selection_box),
    selection_box = selection_box,
    --fast_replaceable_group = "kr-greenhouse",
    module_specification = {
        module_slots = 6
    },
    allowed_effects = { "consumption", "speed", "productivity", "pollution" },
    --animation = {
    --    layers = {
    --        {
    --            filename = kr_entities_path .. "bio-lab/bio-lab.png",
    --            priority = "high",
    --            width = 256,
    --            height = 256,
    --            frame_count = 1,
    --            hr_version = {
    --                filename = kr_entities_path .. "bio-lab/hr-bio-lab.png",
    --                priority = "high",
    --                width = 512,
    --                height = 512,
    --                frame_count = 1,
    --                scale = 0.5,
    --            },
    --        },
    --        {
    --            filename = kr_entities_path .. "bio-lab/bio-lab-sh.png",
    --            priority = "high",
    --            width = 256,
    --            height = 256,
    --            shift = { 0.32, 0 },
    --            frame_count = 1,
    --            draw_as_shadow = true,
    --            hr_version = {
    --                filename = kr_entities_path .. "bio-lab/hr-bio-lab-sh.png",
    --                priority = "high",
    --                width = 512,
    --                height = 512,
    --                shift = { 0.32, 0 },
    --                frame_count = 1,
    --                draw_as_shadow = true,
    --                scale = 0.5,
    --            },
    --        },
    --    },
    --},
    --working_visualisations = {
    --    {
    --        animation = {
    --            filename = kr_entities_path .. "bio-lab/bio-lab-working.png",
    --            width = 193,
    --            height = 171,
    --            shift = { 0.05, -0.31 },
    --            frame_count = 30,
    --            line_length = 5,
    --            animation_speed = 0.35,
    --            hr_version = {
    --                filename = kr_entities_path .. "bio-lab/hr-bio-lab-working.png",
    --                width = 387,
    --                height = 342,
    --                shift = { 0.05, -0.31 },
    --                frame_count = 30,
    --                line_length = 5,
    --                scale = 0.5,
    --                animation_speed = 0.35,
    --            },
    --        },
    --    },
    --},
    crafting_categories = { "crafting" },
    scale_entity_info_icon = true,
    vehicle_impact_sound = sounds.generic_impact,
    --working_sound = bio_lab_working_sound,
    crafting_speed = 1,
    return_ingredients_on_change = true,
    energy_source = {
        type = "electric",
        usage_priority = "secondary-input",
        emissions_per_minute = 10,
    },
    energy_usage = "1MW",
    ingredient_count = 4,
}

table.insert(prototypes, prototype)

data:extend(prototypes)