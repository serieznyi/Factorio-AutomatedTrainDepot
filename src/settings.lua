data:extend({
    -- Console logging level
    {
        type = "string-setting",
        name = "atd-console-level",
        --order = "ad",
        setting_type = "runtime-per-user",
        default_value = "2",
        allowed_values = {"1", "2", "3", "4"}
    },
})