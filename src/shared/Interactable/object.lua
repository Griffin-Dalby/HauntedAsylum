--[[

    Interactable Object

    Griffin Dalby
    2025.09.07

    This module will provide the behavior for Interactable Objects.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local util = require(script.Parent.util)
local types = require(script.Parent.types)
local prompt = require(script.Parent.prompt)
local promptBuilder = require(script.Parent.prompt.uiBuilder)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local world_channel = networking.getChannel('world')

--]] Settings
local __debug = false

--]] Constants
--]] Variables
--]] Functions
--]] Object
local object = {}
object.__index = object

--[[ object.new(opts: ObjectOptions): InteractableObject
    Constructor function for a object, this will sanitize & parse data
    and then authorize the prompt with the server if needed (on the
    client). ]]
function object.new(opts: types._object_options): types.InteractableObject
    assert(opts.object_id, `Missing "object_id" from Object Options! This is a unique identified for this specific object.`)
    assert(type(opts.object_id) == 'string', 
        `"object_id" in Object Options is of type "{type(opts.object_id)}"! It was expected to be a string.`)

    assert(opts.object_name, `Missing "object_name" from Object Options! This is a human-readable name for this object.`)
    assert(type(opts.object_name) == 'string',
        `"object_name" in Object Options is of type "{type(opts.object_name)}"! It was expected to be a string.`)

    assert(opts.instance, `Missing "instance" from Object Options! This is the instance this prompts will be attached to.`)
    assert((typeof(opts.instance) == 'Instance') or (type(opts.instance) == 'table'),
        `"instance" in Object Options is of type "{typeof(opts.instance)}! It was expected to be a Instance, or a descriptive table!`)

    local self = setmetatable({} :: types._self_object, object)

    self.object_id = opts.object_id
    self.object_name = opts.object_name

    self.instances = util.verify.instance(opts.instance)

    self.prompt_defs = opts.prompt_defs or {}
    self.prompt_defs.instance_table = self.instances --> Pass these into inherited prompt_defs
    self.prompt_defs.object_name = self.object_name
    self.prompt_defs.object_id = self.object_id

    self.prompts = {}

    --> Authorize
    if opts.authorized then
        if __debug then print(`[{script.Name}] Attempting to authorize object: {self.object_id}`) end

        local finished, success = false, false
        world_channel.interaction:with()
            :intent('auth')
            :data('object', self.object_id)
            :timeout(3)
            :invoke()
                :andThen(function() success = true end)
                :finally(function() finished = true end)
                :catch(function(err)
                    warn(`[{script.Name}] An issue occured while authorizing object! ({self.object_id})`)
                    if err[1] then
                        warn(`[{script.Name}] A message was provided: {err[1]}`)
                    end
                end)
        repeat task.wait(0) until finished
        if not success then return end
        if __debug then print(`[{script.Name}] Successfully authorized object: {self.object_id}`) end
    end

    return self
end

--[[ object:newPrompt(opts: PromptOptions) : InteractablePrompt
    Wraps prompt.new() and integrates prompt with the current object.]]
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

    local new_prompt = prompt.new(opts, self.prompt_defs)
    self.prompts[opts.prompt_id] = new_prompt
    
    return new_prompt
end

return object