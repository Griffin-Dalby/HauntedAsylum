--[[

    Item Event Endpoints

    Griffin Dalby
    2025.10.13

    This script provides Endpoints for item networking
    events.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local inventory = require(replicatedStorage.Shared.Inventory)
local Titems = require(replicatedStorage.Shared.Item.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local world = networking.getChannel('world')

--> Cache
local inventory_cache = cache.findCache('inventory')
local item_cache = cache.findCache('items')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Endpoints
world.item:route()
    :on('pickup', function(req, res)
        local c_tag = `({req.caller.Name}.{req.caller.UserId}) attempted to pickup an item`

        if not req.data[1] then
            warn(`Player {c_tag}, while missing item UUID!`)
            res.reject('missing item UUID!'); return end
        if not inventory_cache:hasEntry(req.caller) then
            warn(`Player {c_tag}, while not owning an inventory!`)
            res.reject('no inventory'); return end
        local player_inventory = inventory_cache:getValue(req.caller) :: inventory.Inventory
        
        if not item_cache:hasEntry(req.data[1]) then
            warn(`Player {c_tag}, while item w/ uuid "{req.data[1]}" doesn't exist!`)
            res.reject('invalid item UUID'); return end
        local item = item_cache:getValue(req.data[1]) :: Titems.Item

        local success = player_inventory:insert(item)
        if success==true then
            res.data()
            res.send()
        else
            res.reject(success)
        end
    end)