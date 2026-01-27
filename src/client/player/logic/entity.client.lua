--[[

    Entity Client Controller

    Griffin Dalby
    2025.09.21

    This script will control entity data objects on the client-side.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cdn = sawdust.core.cdn

--> CDN
local entity_cdn = cdn.getProvider('entity')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Controller
local entity_controllers = {}

for _, meta: {cdnInfo: { assetId: string }, behavior: { instantiate: () -> any? }} in pairs(entity_cdn:getAllAssets()) do
    
    entity_controllers[meta.cdnInfo.assetId] = meta.behavior.instantiate()

end