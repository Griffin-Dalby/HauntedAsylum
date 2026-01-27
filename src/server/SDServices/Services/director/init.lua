--[[

    Director SDService

    Griffin Dalby
    2026.1.26

    This module will provide a SDService for the Entity Director

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)

local builder = Sawdust.builder

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local Director = builder.new('director')
    :loadMeta(script.meta)
    :init(function(self, deps)
    end)

    :start(function(self)
        --> Initalize Entities
        for i, generator in pairs(script.meta:GetChildren()) do
            generator = require(generator)
            local _gen_entity = generator()
        end
    end)

return Director