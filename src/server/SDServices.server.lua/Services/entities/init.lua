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
        --> Initalize Entities
        for _, generator in pairs(self.meta) do
            local _gen_entity = generator()
        end
    end)

return entity_service