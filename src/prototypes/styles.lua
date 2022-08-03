local styles = data.raw["gui-style"].default

-- Nomenclature: small = size 36; tiny = size 32

-- Imitates a listbox, but allowing for way more customisation by using real buttons
styles["atd_scroll_pane_list_box"] = {
    type = "scroll_pane_style",
    parent = "scroll_pane_with_dark_background_under_subheader",
    extra_right_padding_when_activated = -12,
    background_graphical_set = { -- rubber grid
        position = {282,17},
        corner_size = 8,
        overall_tiling_vertical_size = 22,
        overall_tiling_vertical_spacing = 6,
        overall_tiling_vertical_padding = 4,
        overall_tiling_horizontal_padding = 4
    },
    vertically_stretchable = "on",
    padding = 0,
    vertical_flow_style = {
        type = "vertical_flow_style",
        vertical_spacing = 0
    }
}

-- A button that can be used in a fake list box, but looks identical to the real thing
styles["atd_button_list_box_item"] = {
    type = "button_style",
    parent = "list_box_item",
    left_padding = 4,
    right_padding = 8,
    horizontally_stretchable = "on",
    horizontally_squashable = "on"
}

-- The active style needs to be separate so the selected sub factory can still be clicked
styles["atd_button_list_box_item_active"] = {
    type = "button_style",
    parent = "atd_button_list_box_item",
    default_graphical_set = styles.button.selected_graphical_set,
    hovered_graphical_set = styles.button.selected_hovered_graphical_set,
    clicked_graphical_set = styles.button.selected_clicked_graphical_set,
    default_font_color = styles.button.selected_font_color,
    default_vertical_offset = styles.button.selected_vertical_offset
}

-- The active style needs to be separate so the selected sub factory can still be clicked
styles["error_label"] = {
    type = "label_style",
    font = "default-semibold",
    font_color = { r = 227, g = 44, b = 44 },
}

styles["atd_trains_quantity_textfield"] = {
    type = "textbox_style",
    font_color = { r = 1, g = 1, b = 1, a = 1 },
}

styles["atd_frame_semitransparent"] = {
    type = "frame_style",
    graphical_set = {
        base = {
            type = "composition",
            filename = "__factoryplanner__/graphics/semitransparent_pixel.png",
            corner_size = 1,
            position = {0, 0}
        }
    }
}

styles["atd_frame_transparent"] = {
    type = "frame_style",
    graphical_set = {
        base = {
            type = "composition",
            filename = "__factoryplanner__/graphics/transparent_pixel.png",
            corner_size = 1,
            position = {0, 0}
        }
    }
}