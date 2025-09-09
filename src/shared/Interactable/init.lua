--[[

    Interactable Object Framework

    Griffin Dalby
    2025.09.07

    This module will provide a cohesive "interactable object" system,
    where you create prompts from an object factory.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.types)

local object, prompt = require(script.object), require(script.prompt)
local promptBuilder = require(script.prompt.uiBuilder)
local util = require(script.util)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)
local cache = sawdust.core.cache

--> Cache
local interactable_cache = cache.findCache('interactable')
local objects_cache = interactable_cache:createTable('objects')
local prompt_ui_cache = interactable_cache:createTable('prompt.ui')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Framework
local interactable = {}
interactable.__index = interactable

--[[ OBJECTS ]]--

--[[ interactable.newObject(opts: ObjectOptions) : InteractableObject
    Constructor function for a "Interactable Object".
    
    This Object will describe anything that can be interacted with,
    allowing you to create a special environment for each prompt in
    that specific ecosystem. ]]
function interactable.newObject(opts: types._object_options) : types.InteractableObject
    assert(opts, `Attempt to create new Interactable Object w/o options argument!`)
    assert(type(opts) == 'table',
        `options table is of type "{type(opts)}", it was expected to be... a table!`)

    assert(opts.object_id, `Missing "object_id" option!`)
    assert(type(opts.object_id) == 'string', 
        `"object_id" option is of type "{type(opts.object_id)}", it was expected to be a string!`)

    assert(opts.object_name, `Missing "object_name" option!`)
    assert(type(opts.object_name) == 'string', 
        `"object_name" option is of type "{type(opts.object_name)}", it was expected to be a string!`)

    assert(opts.instance, `Missing "instance" option!`)
    assert(typeof(opts.instance) == 'Instance', 
        `"instance" option is of type "{typeof(opts.instance)}", it was expected to be an instance!`)

    if opts.prompt_defs then
        util.verify.prompt_defs(opts.prompt_defs) --] Verifies & cleans prompt_defs
        end

    assert(not objects_cache:hasEntry(opts.object_id), `Provided object ID "{opts.object_id}" is already registered! Please remember these are to be unique.`)

    local new_object = object.new(opts)
    if new_object then
        objects_cache:setValue(opts.object_id, new_object)
        return new_object
    end
end

--[[ interactable.findObject(object_name: string) : InteractableObject?
    Attempt to locate a specific object saved in the registrar.
    If one is found, it will be returned as an InteractableObject. ]]
function interactable.findObject(object_name: string) : types.InteractableObject?
    assert(object_name, `Missing argument #1 for .findObject()! "object_name"`)
    assert(type(object_name) ~= 'string', 
        `object_name is of type "{type(object_name)}", it was expected to be a string!`)

    if not objects_cache:hasEntry(object_name) then
        warn(`[{script.Name}] Failed to find object w/ name "{object_name}"!`)
        return false; end
    
    return objects_cache:getValue(object_name)
end

--[[ PROMPT UI BUILDER ]]--

--[[ interactable.newPromptUiBuilder(root_ui: Frame, cache_id: string?) : PromptUiBuilder
    Constructor function for a PromptUIBuilder, which upon compilation
    will generate a PromptUI that can be cached (if cache_id is provided). ]]
function interactable.newPromptUiBuilder(root_ui: Frame, cache_id: string?): types.PromptUiBuilder
    local p_builder = promptBuilder.new(root_ui)
    if not p_builder then return end

    if cache_id then
        prompt_ui_cache:setValue(cache_id, p_builder)
    end

    return p_builder
end

--[[ interactable.findPromptUiBuilder(cache_id: string) : PromptUiBuilder?
    Attempt to locate a specific compiled PromptUiBuilder that has been cached. ]]
function interactable.findPromptUiBuilder(cache_id: string) : types.PromptUiBuilder?
    assert(cache_id, `Attempt to .findPromptUiBuilder() with a nil cache_id!`)
    assert(type(cache_id) == "string", `Attempt to .findPromptUiBuilder() with an invalid type of cache_id! A "{type(cache_id)}" was provided, while a string was expected.`)

    if not prompt_ui_cache:hasEntry(cache_id) then
        error(`Failed to locate PromptUiBuilder w/ cache_id "{cache_id}"! Please verify you're caching this id.`) end
    return prompt_ui_cache:getValue(cache_id)
end

return interactable