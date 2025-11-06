--[[

    Locker Server Object

    Griffin Dalby
    2025.10.08

    This module will provide metadata for the locker objects

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Cache
local players_cache = cache.findCache('players')
repeat task.wait(0) until players_cache:hasEntry('session')

local session_cache = players_cache:findTable('session')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Object

return function ()
    local locker_object = interactable.newObject{
        object_id = 'locker',
        object_name = 'Locker',

        instance = {workspace.environment.locker, {}},
        prompt_defs = {
            range = 15
        }
    }

    local hide_prompt = locker_object:newPrompt{
        prompt_id = 'hide',
        action = 'Hide',
        cooldown = .5,
    }
    hide_prompt.triggered:connect(function(self, locker: Model, player: Player)
        local player_data = session_cache:getValue(player)
        if player_data.is_hiding then
            error(`[{script.Name}] Player {player.Name}.{player.UserId} is already hiding!`)
            return end
            
        local character = player.Character
        local humanoid  = character.Humanoid
        local root_part = humanoid.RootPart
        player_data.is_hiding = {locker, root_part.CFrame}
            
        local locker_model = locker.Parent.Parent :: Model
        local body = locker_model['Door']['Body'] :: Part

        body:SetNetworkOwner(player)
        root_part.Anchored = true
        root_part.CFrame = locker.HidingPosition.WorldCFrame
    end)

    return hide_prompt
end