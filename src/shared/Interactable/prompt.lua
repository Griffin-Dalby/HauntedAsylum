--[[

    Interactable Prompt

    Griffin Dalby
    2025.09.07

    This module will provide the behavior for Interactable Prompts.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Object
local prompt = {}
prompt.__index = prompt

function prompt.new(): types.InteractablePrompt
    local self = setmetatable({} :: types._self_prompt, prompt)

    

    return self
end

return prompt