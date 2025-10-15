--[[

    Quest SDService

    Griffin Dalby
    2025.10.15

    This module will provide behavior for Quests on the server-side
    utilizing Sawdust Services.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local builder = sawdust.builder

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local quests_service = builder.new('quests')
    :init(function(self, deps)
        self.player_goals = {}
    end)
    :start(function(self)
        
    end)