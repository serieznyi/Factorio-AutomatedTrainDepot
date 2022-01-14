local main_frame = require("scripts.gui.main_frame")
local add_group_frame = require("scripts.gui.add_group_frame")
local locomotive_configuration_frame = require("scripts.gui.locomotive_configuration_frame")

local index = {}

function index.init()
    global.gui = {}

    main_frame.init()
    add_group_frame.init()
    locomotive_configuration_frame.init()
end

function index.dispatch(action, event)
    local handlers = {
        [main_frame.name()] = function(a, e) main_frame.dispatch(a, e) end,
        [add_group_frame.name()] = function(a, e) add_group_frame.dispatch(a, e) end,
        [locomotive_configuration_frame.name()] = function(a, e) locomotive_configuration_frame.dispatch(a, e) end,
    }

    local handler = handlers[action.gui]

    if handler ~= nil then
        return handler(action, event)
    end

    return false
end

return index