--[[

    Interaction Event Endpoints

    Griffin Dalby
    2025.09.10

    This script provides Endpoints for interaction networking
    events.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)
local intbl_types  = require(replicatedStorage.Shared.Interactable.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Cache
local interactable_cache = cache.findCache('interactable')
local objects_cache = interactable_cache:findTable('objects')

--> Networking
local world_channel = networking.getChannel('world')

--]] Settings
local __debug = true

--]] Constants
--]] Variables
--]] Functions
function locate_object(object_id)
    local s, object = pcall(interactable.findObject, object_id)
    if not s then
        warn(`[{script.Name}] Failure locating object for authorization!`)
        if object then
            warn(`[{script.Name}] A message was provided: {object}`) end
        return false, 'failure locating object' end

    return object
end

--]] Script

local auth_handler = {
    ['object'] = function(data)
        local object_id = unpack(data) :: string
        local res, msg = locate_object(object_id)
        
        return (if res then true else false), msg
    end,

    ['prompt'] = function(data)
        local object_id:string, prompt_id:string = unpack(data)
        local res, msg = locate_object(object_id)

        if not res then
            return res, msg end
        local object = res :: intbl_types.InteractableObject
        local found_prompt = object.prompts[prompt_id]

        return (if found_prompt then true else false), (if found_prompt then nil else 'failure locating prompt')
    end,
}

world_channel.interaction:route()
    :on('auth', function(req, res)
        local auth_type = req.data[1]
        if not auth_type or type(auth_type)~="string"
            or not auth_handler[auth_type] then
            res.reject(`Invalid auth_type!`); return end

        table.remove(req.data, 1)
        local success, msg = auth_handler[auth_type](req.data)

        if __debug then
            print(`[{script.Name}] {auth_type} authorized: {success} | {table.concat(req.data, '.')}`)
        end
        if success then
            res.data(true)
            res.send()
        else
            res.reject(msg)
        end
    end)

    :on('trigger', function(req, res)
        local object_id:string, prompt_id:string = unpack(req.data)
    
        if not object_id or type(object_id)~='string'
            or not objects_cache:hasEntry(object_id) then
            res.reject('Invalid object_id'); return end
        local object = interactable.findObject(object_id)

        if not prompt_id or type(prompt_id)~='string'
            or not object.prompts[prompt_id] then
            res.reject('Invalid prompt_id'); return end
        local prompt = object.prompts[prompt_id]
        local success, message = prompt:trigger(req.caller)

        if success then
            res.data(true)
            res.send()
        else
            res.reject(message)
        end
    end)