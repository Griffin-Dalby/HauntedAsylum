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
    assert(opts.object_id, `Missing "object_id" from Object Options! This is a unique identified for this specific object.`)
    assert(type(opts.object_id) == 'string', 
        `"object_id" in Object Options is of type "{type(opts.object_id)}"! It was expected to be a string.`)

    assert(opts.object_name, `Missing "object_name" from Object Options! This is a human-readable name for this object.`)
    assert(type(opts.object_name) == 'string',
        `"object_name" in Object Options is of type "{type(opts.object_name)}"! It was expected to be a string.`)

    assert(opts.instance, `Missing "instance" from Object Options! This is the instance this prompts will be attached to.`)
    assert(typeof(opts.instance) == 'Instance',
        `"instance" in Object Options is of type "{typeof(opts.instance)}! It was expected to be a Isntance.`)

    local self = setmetatable({} :: types._self_object, object)

    self.object_id = opts.object_id
    self.object_name = opts.object_name

    self.instance = opts.instance

    self.prompt_defs = opts.prompt_defs or {}
    self.prompt_defs.instance = self.instance
    self.prompt_defs.object_name = self.object_name

    self.prompts = {}

    return self
end

function object:newPrompt(opts: types._prompt_options): types.InteractablePrompt
    assert(opts, `Attempt to create new Interactable Prompt w/o options argument!`)
    assert(type(opts) == 'table',
        `options table is of type "{type(opts)}".`)

    assert(opts.prompt_id, `Missing "prompt_id" option!`)
    assert(type(opts.prompt_id) == 'string', 
        `"prompt_id" option is of type "{type(opts.prompt_id)}", it was expected to be a string!`)

    assert(opts.action, `Missing "action" option!`)
    assert(type(opts.action) == 'string', 
        `"action" option is of type "{type(opts.action)}", it was expected to be a string!`)
    
    assert(self.prompts[opts.prompt_id]==nil, `{self.object_id} already has a prompt w/ id "{opts.prompt_id}"! Remember, these are to be unique!`)

    local new_prompt = prompt.new(opts, self.prompt_defs, {self.object_id, self.object_name})
    self.prompts[opts.prompt_id] = new_prompt
    
    return new_prompt
end

return object