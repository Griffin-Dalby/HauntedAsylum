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

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
local inventory = inventory_intf.new()