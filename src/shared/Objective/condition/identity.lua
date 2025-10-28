--[[

    Objective Conditional Identity

    Griffin Dalby
    2025.10.28

    This module will provide a interface for the Identity found within
    conditionals.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local identity = {}
identity.__index = identity

function identity.new(): types.ConditionIdentity
    local self = setmetatable({}::types.self_condition_identity,identity)

    return self
end

return identity