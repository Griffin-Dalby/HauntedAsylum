--[[

    Authorative Door behavior

    Griffin Dalby
    2025.09.10

    This module will provide behavior for doors, mostly for authority &
    replication for a player opening a door.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local https = game:GetService('HttpService')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)
local doorBehavior = require(replicatedStorage.Shared.ObjectBehavior.door)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local map_cache = cache.findCache('map')
local door_cache = map_cache:createTable('doors', true)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Door
return function ()
    local door_object = interactable.newObject{
        object_id = 'door',
        object_name = 'Door',

        authorized = false,

        instance = {workspace.doors, {}},
        prompt_defs = {
            range = 10
        }
    }

    local door_interact = door_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = .5,
    }
    door_interact.triggered:connect(function(self, door: Part, player: Player)
        --> Replication
        local network_uuid = https:GenerateGUID(false)
        door:SetAttribute('network_id', network_uuid)
        door:SetNetworkOwner(player)
        task.delay(door_interact.cooldown*2, function()
            if door:GetAttribute('network_id')==network_uuid then
                door:SetNetworkOwner(nil)
                door:SetAttribute('network_id', nil)
            end
        end)

        --> Caching
        local door_model = door.Parent :: Model
        local door_object: doorBehavior.Door
        if door_cache:hasEntry(door_model) then
            door_object = door_cache:getValue(door_model)
        else
            door_object = doorBehavior.new(door_model)
            --> doorBehavior.new() already caches the door.
        end

        --> Open/Close
        if door_object.is_open then
            door_object:close()
        else
            door_object:open(player)
        end
    end)

    return door_object
end