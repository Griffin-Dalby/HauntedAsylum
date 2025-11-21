--[[

    Asylum SDService

    Griffin Dalby
    2025.11.19

    This module will provide a SDService while will control the Asylum;
    it's behavior, timings, and other things like tracking which 
    room / floor any given player is on.

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScripts = game:GetService('ServerScriptService')

--]] Modules
local AsylumMap = require(ServerScripts.logic["asylum.map"])

--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)

local Builder = Sawdust.builder

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
type self = {
    mappings: AsylumMap.Mapper
}

local AsylumService = Builder.new('asylum')
    :init(function(self: self, deps)
        
    end)

    :start(function(self: self)
        
    end)

return AsylumService