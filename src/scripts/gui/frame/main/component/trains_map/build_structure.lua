local public = {}
local private = {}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param caption table localized string
function public.get(caption)
    return {
        type = "frame",
        direction = "vertical",
        style_mods = {
            vertically_stretchable = true,
            horizontally_stretchable = true,
        },
        ref = { "component" },
        children = {
            -- Titlebar
            {
                type = "flow",
                direction = "vertical",
                children = {
                    {
                        type = "label",
                        caption = caption,
                    },
                    {
                        type = "line",
                    },
                }
            },
            -- Content
            {
                type = "flow",
                style_mods = {
                    vertically_stretchable = true,
                    horizontally_stretchable = true,
                },
                children = {
                    {
                        type = "scroll-pane",
                        horizontal_scroll_policy = "never",
                        children = {
                            {
                                type = "table",
                                style = "trains_table",
                                ref = {"trains_table"},
                                column_count = 4,
                            }
                        }
                    }
                }
            },
        }
    }
end

return public