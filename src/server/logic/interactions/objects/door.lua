--[[

    Example Object & Prompt Decleration (SERVER)

    Griffin Dalby
    2025.09.10

    This module will provide example data for object & prompt
    registration on the server side.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

local doors_open = {}

return function ()
    local test_object = interactable.newObject{
        object_id = 'door',
        object_name = 'Door',

        instance = {workspace.doors, {}},
        prompt_defs = {
            range = 10
        }
    }

    local test_prompt = test_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = .5,
    }
    test_prompt.triggered:connect(function(self, door: Model, player: Player)
        local hinge = door.Parent.PrimaryPart:FindFirstChildWhichIsA('HingeConstraint')

        if not doors_open[door] then
            doors_open[door] = true
            hinge.TargetAngle = 90
        else
            doors_open[door] = nil
            hinge.TargetAngle = 0
        end
    end)

    return test_object
end