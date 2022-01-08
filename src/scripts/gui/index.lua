local gui_main_frame = require("main_frame")

local index = {}

function index.init()
    gui_main_frame.init()
end

function index.handle_action(action, event)
    if action.gui == gui_main_frame.get_name() then
        return gui_main_frame.handle_action(action, event)
    end

    return false
end

return index