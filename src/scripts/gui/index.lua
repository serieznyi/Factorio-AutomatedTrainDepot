local main_frame = require("scripts.gui.main_frame")
local add_group_frame = require("scripts.gui.add_group_frame")

local index = {}

function index.init()
    global.gui = {}

    main_frame.init()
    add_group_frame.init()
end

function index.dispatch(action, event)
    if action.gui == main_frame.get_name() then
        return main_frame.dispatch(action, event)
    elseif action.gui == add_group_frame.get_name() then
        return add_group_frame.dispatch(action, event)
    end

    return false
end

return index