--[[

    Entity SDService

    Griffin Dalby
    2025.11.02

    This module will provide a SDService for Entity behavior,
    allowing a much more flexible ecosystem and centralized
    control.

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
local entity_service = builder.new('entities')
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

return entity_service