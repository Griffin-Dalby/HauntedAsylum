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

    

    return self
end

return object