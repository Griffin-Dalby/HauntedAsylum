--[[

    Entity Object

    Griffin Dalby
    2025.09.15

    This module will provide a basic entity object, which can be easily used to
    compile new entities and use similar or create new behavior patterns.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local https = game:GetService('HttpService')

--]] Module
local types = require(script.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local fsm = sawdust.core.states

--]] Settings
--]] Constants
--]] Variables
--]] Entity
local entity = {}
entity.__index = entity

function entity.new(identity: {id: string, name: string}) : types.Entity
    local self = setmetatable({} :: types.self_entity, entity)

    assert(identity.id, `Attempt to create a new entity with a nilset id!`)
    assert(identity.name, `Attempt to create a new entity with a nilset name!`)
    
    assert(type(identity.id) == 'string', `Type mismatch for Argument 1, a {type(identity.id)} was provided, but a string was expected.`)
    assert(type(identity.name) == 'string', `Type mismatch for Argument 2, a {type(identity.name)} was provided, but a string was expected.`)

    self.id = identity.id
    self.name = identity.name
    self.fsm = fsm.create()

    return self
end

return entity