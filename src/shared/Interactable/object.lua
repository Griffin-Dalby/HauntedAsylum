--[[

    Interactable Object

    Griffin Dalby
    2025.09.07

    This module will provide the behavior for Interactable Objects.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.Parent.types)
local prompt = require(script.Parent.prompt)
local promptBuilder = require(script.Parent.prompt.uiBuilder)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Object
local object = {}
object.__index = object

function object.new(opts: types._object_options): types.InteractableObject
    local self = setmetatable({} :: types._self_object, object)

    self.object_id = opts.object_id
    self.object_name = opts.object_name

    self.instance = opts.instance
    self.prompt_defs = opts.prompt_defs

    self.prompts = {}

    return self
end

function object:newPrompt(opts: types._prompt_options): types.InteractablePrompt
    local new_prompt = prompt.new(opts, self.prompt_defs)
    self.prompts[opts.action] = new_prompt
    
    return new_prompt
end

return object