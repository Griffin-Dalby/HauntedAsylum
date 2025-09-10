--[[

    Example Object & Prompt Decleration

    Griffin Dalby
    2025.09.10

    This module will provide data for generating objects & prompts.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

return function ()
    local test_object = interactable.newObject{
        object_id = 'test_object',
        object_name = 'Test Object',

        instance = workspace:WaitForChild('Part')
    }

    local test_prompt = test_object:newPrompt{
        action = 'Interact',

    }


    return test_object
end