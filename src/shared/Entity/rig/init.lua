--[[

    Entity Rig

    Griffin Dalby
    2025.09.16

    This module will provide a object that holds & handles the entities
    rig.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.types)
local animator = require(script.animator)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Rig
local rig = {}
rig.__index = rig

function rig.new(rig_data: types.RigData) : types.EntityRig
    local self = setmetatable({} :: types.self_rig, rig)

    assert(rig_data.model, `Missing "model" in RigData!`)
    assert(typeof(rig_data.model)=='Instance' and rig_data.model:IsA('Model'),
        `"model" in RigData isn't a model!`)
    self.model = rig_data.model
    self.animator = animator.new()

    return self
end

return rig