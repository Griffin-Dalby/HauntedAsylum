--[[

    Watcher Entity Descriptor

    Griffin Dalby
    2025.09.16

    This module provides meta for the watcher entity

--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Entity = require(ReplicatedStorage.Shared.Entity)

local sawdust = require(ReplicatedStorage.Sawdust)
local cdn = sawdust.core.cdn

local entity_provider = cdn.getProvider('entity')

return function()

    local self = entity_provider:getAsset('watcher').behavior.instantiate() :: Entity.Entity<Entity.FSM_Cortex>
    self.fsm:switchState("idle")

    return self

end