--- @module scripts.lib.VirtualInventory
local VirtualInventory = {
    ---@type uint
    size = nil,
    ---@type table
    stacks = {},
}

---@param item SimpleItemStack
---@return bool
function VirtualInventory:try_insert(item)
    local item_stack_size = game.item_prototypes[item.name].stack_size

    for i = 1, self.size do
        local stack = self.stacks[i]

        if stack.name == nil and item.count <= item_stack_size then
            self.stacks[i] = item

            return true
        elseif stack.name == nil and item.count > item_stack_size then
            self.stacks[i] = {name = item.name, count = item_stack_size}

            return self:try_insert({name = item.name, count = item.count - item_stack_size})
        elseif stack.name == item.name and stack.count < item_stack_size then
            local can_insert_count = item_stack_size - stack.count

            if item.count <= can_insert_count then
                self.stacks[i].count = stack.count + item.count
                return true
            end

            self.stacks[i].count = stack.count + can_insert_count

            return self:try_insert({name = item.name, count = item.count - can_insert_count})
        end
    end

    return false
end

---@param size uint
---@return scripts.lib.VirtualInventory
function VirtualInventory.new(size)
    ---@type scripts.lib.VirtualInventory
    local self = {}
    setmetatable(self, { __index = VirtualInventory })

    self.size = assert(size, "size is nil")
    self.stacks = {}

    for i = 1, size do
        self.stacks[i] = {}
    end

    return self
end

return VirtualInventory