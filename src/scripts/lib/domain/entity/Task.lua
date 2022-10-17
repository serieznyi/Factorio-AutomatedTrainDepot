--- @module scripts.lib.domain.entity.Task
local Task = {
    ---@type uint
    type = defines.type,
    ---@type bool
    deleted = false,
}

---@return table
function Task:delete()
    self.deleted = true
end

return Task