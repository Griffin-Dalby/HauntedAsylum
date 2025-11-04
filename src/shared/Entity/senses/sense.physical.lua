--[[

    Player Entity Senses

    Griffin Dalby
    2025.11.02

    This module will provide senses to make actions based off of player
    data.

--]]

--]] Services
--]] Modules
local sense_types = require(script.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module

--> Sense Generator
return function(cortex: sense_types.EntityCortex) : sense_types.PhysicalSense
    local sense = {} :: sense_types.self_sense_physical
    setmetatable(sense, {__index = sense})

    local _settings = cortex.__settings.physical

    --> Simple Spatial Awareness
    function sense:getDiff(point: Vector3) : Vector3
        assert(cortex.__body, `cortex is missing __body! Please ensure injection of rig.`)
        local root = cortex.__body.PrimaryPart
        return (root.Position-point)
    end

    function sense:getDistance(point: Vector3) : number
        return sense:getDiff(point).Magnitude end
    function sense:getDirection(point: Vector3) : Vector3
        return sense:getDiff(point).Unit end

    return sense
end