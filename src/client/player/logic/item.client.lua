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
local Titem = require(replicatedStorage.Shared.Item.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local world = networking.getChannel('world')

--> Cache
local item_cache = cache.findCache('items')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
world.item:route()
    :on('instantiate', function(req, res)
        local new_item = Iitem.new(req.data[1], req.data[2])
        if req.data[3] then
            new_item:setTransform(req.data[3])
        end
    end)
    :on('transform', function(req, res)
        local this_item = item_cache:getValue(req.data[1]) :: Titem.Item
        this_item:setTransform(req.data[2])
    end)