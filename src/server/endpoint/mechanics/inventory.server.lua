--[[

    Inventory Event Endpoints

    Griffin Dalby
    2025.10.06

    This script provides endpoints for inventory networking
    events.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local inventory = require(replicatedStorage.Shared.Inventory)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Cache
local inventory_cache = cache.findCache('inventory')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
function pTag(p: Player)
    return `{p.Name}.{p.UserId}` end

--]] Script
mechanics.inventory:route()
    :on('instantiate', function(req, res)
        local inventory, err = inventory.new(req.caller)
        if inventory then
            res.data()
            res.send()
        else
            res.reject(err)
        end
    end)