local constants = require("scripts.gui.frame.add_template.component.train_builder.constants")

local COMPONENT = constants.COMPONENT

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
                    on_elem_changed = { target = COMPONENT.NAME, action = mod.defines.gui.actions.refresh_train_part },
                }
            },
            {
                type = "sprite-button",
                ref = { "delete_button" },
                tags = {train_part_id = train_part_id },
                visible = false,
                tooltip = {"add-train-template-frame.atd-delete-carrier-button"},
                style = "flib_slot_button_red",
                sprite = "atd_sprite_trash",
                actions = {
                    on_click = { target = COMPONENT.NAME, action = mod.defines.gui.actions.delete_train_part }
                }
            },
            {
                type = "sprite-button",
                visible = false,
                tags = { train_part_id = train_part_id, direction = mod.defines.train.direction.in_direction, current_direction = mod.defines.train.direction.in_direction },
                ref = {"carrier_direction_left_button"},
                tooltip = {"add-train-template-frame.atd-сhange-direction-of-locomotive"},
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_left",
                actions = {
                    on_click = { target = COMPONENT.NAME, action = mod.defines.gui.actions.change_carrier_direction },
                }
            },
            {
                type = "sprite-button",
                tags = { train_part_id = train_part_id, direction = mod.defines.train.direction.opposite_direction, current_direction = mod.defines.train.direction.in_direction },
                ref = {"carrier_direction_right_button"},
                visible = false,
                tooltip = {"add-train-template-frame.atd-сhange-direction-of-locomotive"},
                style = "flib_slot_button_default",
                sprite = "atd_sprite_arrow_right",
                actions = {
                    on_click = { target = COMPONENT.NAME, action = mod.defines.gui.actions.change_carrier_direction },
                }
            },
            {
                type = "sprite-button",
                ref = { "locomotive_config_button" },
                tooltip = {"add-train-template-frame.atd-configure-locomotive-button"},
                name = "locomotive_config_button",
                tags = {train_part_id = train_part_id },
                visible = false,
                style = "flib_slot_button_default",
                sprite = "atd_sprite_gear",
            },
        }
    }
end

return build_structure