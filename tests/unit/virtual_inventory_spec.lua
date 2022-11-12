local VirtualInventory = require("src.scripts.lib.VirtualInventory")

describe("VirtualInventory", function()
    setup(function()
        _G.util = require("tests.util")
        _G.game = {
            item_prototypes = {
                ["item1"] = {
                    stack_size = 5
                }
            }
        }
    end)

    it("should contains correct storage stacks quantity", function()
        local definedSize = 10
        local virtualInventory = VirtualInventory.new(definedSize)

        assert.are.equal(definedSize, #virtualInventory.stacks)
    end)

    it("should insert new stack item in empty storage", function()
        local virtualInventory = VirtualInventory.new(3)

        assert.are.True(virtualInventory:try_insert({name = "item1", count = 5}))
        assert.are.equal(virtualInventory.stacks[1]['name'], "item1")
        assert.are.equal(virtualInventory.stacks[1]['count'], 5)
    end)

    it("should append items to not filled stack", function()
        local virtualInventory = VirtualInventory.new(3)

        virtualInventory:try_insert({name = "item1", count = 4})

        virtualInventory:try_insert({name = "item1", count = 2})

        assert.are.equal(virtualInventory.stacks[1]['name'], "item1")
        assert.are.equal(virtualInventory.stacks[1]['count'], 5)
        assert.are.equal(virtualInventory.stacks[2]['name'], "item1")
        assert.are.equal(virtualInventory.stacks[2]['count'], 1)
    end)
end)