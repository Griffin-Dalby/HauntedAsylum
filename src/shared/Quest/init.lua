--[[

    Quest Interface

    Griffin Dalby
    2025.10.15

    This module will provide a comprehensive interface to handle
    quest prompts for players.

--]]

--]] Services


--]] Modules
local types = require(script.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local quest = {}
quest.__index = quest

function quest.new() : types.Quest
    local self = setmetatable({}::types.self_quest, quest)

    

    return self
end

return quest