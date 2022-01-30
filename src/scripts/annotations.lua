---------------------------------------------------------------------------
-- -- -- Group
---------------------------------------------------------------------------

---@class atd.TrainTemplate
local TrainTemplate = {}

---@type uint
TrainTemplate.id = nil

---@type string
TrainTemplate.name = nil

---@type string
TrainTemplate.icon = nil

---@type table Set of TrainPart
---@see atd.TrainPart
TrainTemplate.train = nil

---@type uint
TrainTemplate.enabled = false

---@type uint
TrainTemplate.amount = nil

---------------------------------------------------------------------------
-- -- -- Train
---------------------------------------------------------------------------

---@class atd.Train
local Train = {}

---@type uint
Train.id = nil

---@type uint
Train.train_template_id = nil

---@type bool
Train.uncontrolled_train = nil

---@type uint
Train.state = nil

---@type LuaTrain
Train.train = nil

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