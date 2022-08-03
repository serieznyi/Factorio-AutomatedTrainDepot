local flib_gui = require("__flib__.gui")

local structure = require("scripts.gui.component.trains_map.structure")

--- @module gui.component.TrainsMap
local TrainsMap = {
    name = "trains_map",
    ---@type LuaGuiElement
    container = nil,
    ---@type LuaPlayer
    player = nil,
    ---@type table
    refs = {
        ---@type LuaGuiElement
        trains_table = nil,
    },
}

---@param player LuaPlayer
---@param container LuaGuiElement
---@param trains table
function TrainsMap.new(player, container, trains)
    ---@type gui.component.TrainsMap
    local self = {}
    setmetatable(self, { __index = TrainsMap })

    assert(player, "player is nil")
    self.player = player

    assert(container, "container is nil")
    self.container = container

    self:_initialize(trains)

    mod.log.debug("Component {1} created", {self.name}, self.name)

    return self
end

function TrainsMap:destroy()
    self.refs.trains_table.destroy()
end

---@param trains table
function TrainsMap:_initialize(trains)
    local caption = {"trains-map.atd-uncontrolled-trains"}
    self.refs = flib_gui.build(self.container, { structure.get(caption)})

    if trains ~= nil then
        self:_refresh_component(trains)
    end
end

function TrainsMap:_refresh_component(trains)
    ---@type LuaGuiElement
    local trains_table = self.refs.trains_table

    trains_table.clear()

    -----@param train scripts.lib.domain.Train
    for _, train in ipairs(trains) do
        local locomotive = train:get_main_locomotive()

        flib_gui.add(trains_table, {
            type = "frame",
            style = "train_with_minimap_frame",
            children = {
                {
                    type = "minimap",
                    zoom = 1.5,
                }
            }
        })

        trains_table.children[#trains_table.children].children[1].entity = locomotive
    end
end

function TrainsMap:update(trains)
    self:_refresh_component(trains)
end

return TrainsMap