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

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)
local cache = sawdust.core.cache

--> Cache
local interactable_cache = cache.findCache('interactable')
local objects_cache = interactable_cache:createTable('objects')

--]] Settings
local _default_prompt_defs = {
    interact_gui = '',
    interact_bind = { Enum.KeyCode.E, Enum.KeyCode.ButtonX },

    range = 7.5,
    raycast = true,

    hold_time = 1,
}

--]] Constants
--]] Variables
--]] Functions
--]] Framework
local interactable = {}
interactable.__index = interactable

--[[ interactable.newObject(opts: ObjectOptions) : InteractableObject
    Constructor function for a "Interactable Object".
    
    This Object will describe anything that can be interacted with,
    allowing you to create a special environment for each prompt in
    that specific ecosystem. ]]
function interactable.newObject(opts: types._object_options) : types.InteractableObject
    assert(opts, `Attempt to create new Interactable Object w/o options argument!`)
    assert(type(opts) == 'table',
        `options table is of type "{type(opts)}", it was expected to be... a table!`)

    assert(opts.object_name, `Missing "object_name" option!`)
    assert(type(opts.object_name) == 'string', 
        `"object_name" option is of type "{type(opts.object_name)}", it was expected to be a string!`)

    assert(opts.instance, `Missing "instance" option!`)
    assert(typeof(opts.instance) == 'Instance', 
        `"instance" option is of type "{typeof(opts.instance)}", it was expected to be an instance!`)

    if opts.prompt_defs then
        local _dpd_ = _default_prompt_defs

        for i, v in pairs(opts.prompt_defs) do
            if not _dpd_[i] then
                warn(`[{script.Name}] Invalid prompt_def key found! (Caught: {i})`)
                opts.prompt_defs[i] = nil; continue end

            if not (type(v) ~= type(_dpd_[i]))
                and not (typeof(v) ~= typeof(_dpd_[i])) then
                    warn(`[{script.Name}] prompt_def key found w/ invalid type! ({i} is a {type(v)}/{typeof(v)}; expected {type(_default_prompt_defs[i])}/{typeof(_default_prompt_defs[i])}.`)
                    opts.prompt_defs[i] = _dpd_[i]; continue end
        end
    end

    assert(not objects_cache:hasEntry(opts.object_name), `Provided object name "{opts.object_name}" is already registered! Please remember these are to be unique.`)

    local new_object = object.new(opts)
    if new_object then
        objects_cache:setValue(opts.object_name)
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

return interactable