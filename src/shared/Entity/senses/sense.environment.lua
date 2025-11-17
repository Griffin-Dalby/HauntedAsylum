--[[

    Entity Environmental Sense

    Griffin Dalby
    2025.11.17

    This module will provide an environmental sense for entities,
    allowing them to understand and interact with their surroundings
    easier.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local sense_types = require(script.Parent.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local asylum = sawdust.services:getService('asylum')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
return function(cortex: sense_types.EntityCortex)
    local sense = {}
    setmetatable(sense, {__index = sense})

    --> Asylum Mapping


    return sense
end