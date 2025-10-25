--[[

    Door Behavior

    Griffin Dalby
    2025.10.23

    This module will provide behaviors for doors, client-sided. This allows
    for responsive mechanics.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')

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
--]] Constant
--]] Variables
--]] Functions
--]] Door
return function ()
    local door_object = interactable.newObject{
        object_id = 'door',
        object_name = 'Door',
        authorized = true,

        prompt_defs = {
            interact_gui = 'basic',
            interact_bind = { desktop = Enum.KeyCode.E, console = Enum.KeyCode.ButtonX },
            authorized = true,
            range = 10
        },

        instance = {workspace.doors, {}},
    }

    local door_interact = door_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = 1,

    }
    door_interact.triggered:connect(function(self, door: Part)
        --> Cache
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
            door_object:open(players.LocalPlayer)
        end
    end)

    return door_object
end