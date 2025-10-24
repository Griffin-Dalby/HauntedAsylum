--[[

    Net Event

    Griffin Dalby
    2025.10.24

    This module will provide the networking pipeline for prompts,
    allowing ease of communication between either context.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module

local netEvent = {}
netEvent.__index = netEvent

function netEvent.new(object: types.InteractableObject) : types.NetEvent
    local self = setmetatable({} :: types._self_net_event, netEvent)



    return self
end

return netEvent