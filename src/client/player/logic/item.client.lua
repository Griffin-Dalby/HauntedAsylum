--[[

    Item Client Controller

    Griffin Dalby
    2025.10.13

    This script controls items on the client-side.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local Iitem = require(replicatedStorage.Shared.Item)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local world = networking.getChannel('world')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
world.item:route()
    :on('instantiate', function(req, res)
        local new_item = Iitem.new(req.data[1], req.data[2])
        
    end)