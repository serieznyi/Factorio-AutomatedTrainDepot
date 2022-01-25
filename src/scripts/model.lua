---------------------------------------------------------------------------
-- -- -- Group
---------------------------------------------------------------------------

---@class atd.TrainGroup
local TrainGroup = {}

---@type uint
TrainGroup.id = nil

---@type string
TrainGroup.name = nil

---@type string
TrainGroup.icon = nil

---@type table Set of TrainPart
---@see atd.TrainPart
TrainGroup.train = nil

---------------------------------------------------------------------------
-- -- -- TrainPart
---------------------------------------------------------------------------

---@class atd.TrainPart
local TrainPart = {}

---@type string
TrainPart.type = nil

---@type string
TrainPart.entity = nil

---@type uint
TrainPart.direction = nil

---@type bool
TrainPart.use_any_fuel = nil

---------------------------------------------------------------------------
-- -- -- LocomotiveDirection
---------------------------------------------------------------------------