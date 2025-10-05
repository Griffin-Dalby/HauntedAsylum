--[[

    Example Entity Descriptor

    Griffin Dalby
    2025.09.16

    This module provides an example for entity meta.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')

local sawdust = require(replicatedStorage.Sawdust)
local cdn = sawdust.core.cdn

local entity_provider = cdn.getProvider('entity')

return function()

    local self = entity_provider:getAsset('example').behavior.instantiate()
    self:spawn()

    return self

end