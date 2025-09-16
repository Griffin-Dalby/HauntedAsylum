--[[

    Example Object & Prompt Decleration (SERVER)

    Griffin Dalby
    2025.09.10

    This module will provide example data for object & prompt
    registration on the server side.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

workspace:WaitForChild('doors'):WaitForChild('RedDoor')
workspace.doors:WaitForChild('BlueDoor')
workspace.doors:WaitForChild('GreenDoor')

local door_open = false

return function ()
    local test_object = interactable.newObject{
        object_id = 'door',
        object_name = 'Door',

        instance = {workspace.doors, {}},
    }

    local test_prompt = test_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = 1,
    }
    test_prompt.triggered:connect(function(self, door: Model, player: Player)
        local hinge = door.Parent.PrimaryPart:FindFirstChildWhichIsA('HingeConstraint')

        if not door_open then
            hinge.TargetAngle = 90
            door_open = true
        else
            hinge.TargetAngle = 0
            door_open = false
        end
    end)

    return test_object
end