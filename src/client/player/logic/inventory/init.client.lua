--[[

    Inventory Client Controller

    Griffin Dalby
    2025.09.17

    This script will control the client-side Inventory system

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local inventory_intf = require(replicatedStorage.Shared.Inventory)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local env = cache.findCache('env')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
local inventory = inventory_intf.new()
env:setValue('inventory', inventory)