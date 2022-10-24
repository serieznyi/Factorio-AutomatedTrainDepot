local logger = require("scripts.lib.logger")

local public = {}

local private = {
    names = {},
    stats = {},
    ---@type uint
    ttl = nil,
}

---------------------------------------------------------------------------
-- -- -- PRIVATE
---------------------------------------------------------------------------

function private.stat_increase(name)
    private.stats[name] = private.stats[name] + 1
end

function private.reset()
    for i, _ in pairs(private.stats) do
        private.stats[i] = 0
    end
end

function private.count()
    local count = 0

    for _, v in pairs(private.stats) do
        count = count + v
    end

    return count
end

function private.report()
    if private.count() > 0 then
        for name, v in pairs(private.stats) do
            logger.debug("Remove entries: {1} {2}", {name, v}, "persistence_storage.gc")
        end

        private.reset()
    end
end

---@param entry table
---@param current_tick uint
function private.is_expired(entry, current_tick)
    if not entry.updated_at then
        return false
    end

    local ttl = entry.updated_at + private.ttl

    return ttl >= current_tick and entry.deleted == true
end

function private.init()
    for _, v in ipairs(private.names) do
        private.stats[v] = 0
    end
end

---------------------------------------------------------------------------
-- -- -- PUBLIC
---------------------------------------------------------------------------

---@param storage_names table list of keys in global
---@param ttl uint
function public.init(storage_names, ttl)
    assert(type(storage_names) == "table", "storage_names must be table")

    private.names = storage_names
    private.ttl = assert(ttl, "ttl is nil")

    private.init()
end

---@param tick uint
function public.collect_garbage(tick)
    for _, name in ipairs(private.names) do
        for i, v in pairs(global[name] or {}) do
            if private.is_expired(v, tick) then
                global[name][i] = nil
                private.stat_increase(name)
            end
        end
    end

    private.report()
end

---@param data table
---@return table
function public.with_updated_at(data)
    data.updated_at = game.tick

    return data
end

return public