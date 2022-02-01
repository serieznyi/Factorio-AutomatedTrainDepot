local public = {}
local private = {}

local trains_map

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param id uint
function public.get_train(id)
    ---@param force LuaForce
    for _, force in pairs(game.forces) do
        ---@param lua_train LuaTrain
        for _, lua_train in pairs(force.get_trains()) do
            if lua_train.id == id then
                return lua_train
            end
        end
    end

    return nil
end

function public.get_trains()
    local trains = {}
    ---@param force LuaForce
    for _, force in pairs(game.forces) do
        ---@param lua_train LuaTrain
        for _, lua_train in pairs(force.get_trains()) do
            table.insert(trains, lua_train)
        end
    end

    return trains
end

return public