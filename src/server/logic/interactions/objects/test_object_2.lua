--[[

    Example Object & Prompt Decleration (SERVER)

    Griffin Dalby
    2025.09.10

    This module will provide example data for object & prompt
    registration on the server side.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

return function ()
    local test_object = interactable.newObject{
        object_id = 'test_object_2',
        object_name = 'Test Object 2',

        instance = {workspace, {Name = 'TestPart2'}},
    }

    local test_prompt = test_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = 1,
    }
    test_prompt.triggered:connect(function()
        print('server triggered 2')
    end)

    return test_object
end