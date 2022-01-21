local constants = require("scripts.gui.frame.add_group.component.train_builder.constants")

local COMPONENT_NAME = constants.COMPONENT_NAME
local ACTION = constants.ACTION
local LOCOMOTIVE_DIRECTION = constants.LOCOMOTIVE_DIRECTION

local build_structure = {}

---@param train_part_id int
function build_structure.get(train_part_id)
    return {
        type = "flow",
        direction = "vertical",
        ref = { "element" },
        tags = {train_part_id = train_part_id },
        children = {
            {
                type = "choose-elem-button",
                tags = {train_part_id = train_part_id },
                ref = { "part_chooser" },
                elem_type = "entity",
                elem_filters = {
                    {filter="rolling-stock"},
                },
                actions = {
                    on_elem_changed = { gui = COMPONENT_NAME, action = ACTION.TRAIN_CHANGED },
                }
            },
            {
                type = "sprite-button",
                ref = { "delete_button" },
                tags = {train_part_id = train_part_id },
                visible = false,
                style = "flib_slot_button_red",
                sprite = "atd_sprite_trash",
                actions = {
                    on_click = { gui = COMPONENT_NAME, action = ACTION.DELETE_TRAIN_PART }
                }
            },
            {
                type = "sprite-button",
                ref = { "locomotive_config_button" },
                name = "locomotive_config_button",
                tags = {train_part_id = train_part_id },
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
                on_click = { gui = "locomotive_configuration_frame", action = "open" },
            },
            {
                type = "sprite-button",
                visible = false,
                tags = { train_part_id = train_part_id, direction = LOCOMOTIVE_DIRECTION.LEFT },
                ref = {"locomotive_direction_left_button"},
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_left",
                actions = {
                    on_click = { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                }
            },
            {
                type = "sprite-button",
                tags = { train_part_id = train_part_id, direction = LOCOMOTIVE_DIRECTION.RIGHT },
                ref = {"locomotive_direction_right_button"},
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_right",
                actions = {
                    on_click = { gui = COMPONENT_NAME, action = ACTION.CHANGE_LOCOMOTIVE_DIRECTION },
                }
            }
        }
    }
end

return build_structure