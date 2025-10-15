--[[

    Locker Server Object

    Griffin Dalby
    2025.10.08

    This module will provide metadata for the locker objects

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

local doors_open = {}

return function ()
    local test_object = interactable.newObject{
        object_id = 'locker',
        object_name = 'Locker',

        instance = {workspace.environment.locker, {}},
        prompt_defs = {
            range = 45
        }
    }

    local test_prompt = test_object:newPrompt{
        prompt_id = 'hide',
        action = 'Hide',
        cooldown = .5,
    }
    test_prompt.triggered:connect(function(self, locker: Model, player: Player)
        local character = player.Character
        local humanoid  = character.Humanoid
        local root_part = humanoid.RootPart

        local locker_model = locker.Parent.Parent :: Model
        local body = locker_model['Door']['Body'] :: Part

        body:SetNetworkOwner(player)
        -- root_part.Anchored = true
        -- root_part.CFrame = locker.HidingPosition.WorldCFrame
    end)

    return test_object
end