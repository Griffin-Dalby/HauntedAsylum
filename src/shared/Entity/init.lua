--[[

    Entity Object

    Griffin Dalby
    2025.09.15

    This module will provide a basic entity object, which can be easily used to
    compile new entities and use similar or create new behavior patterns.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Module
local types = require(script.types)
local rig = require(script.rig)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local fsm = sawdust.core.states
local cdn = sawdust.core.cdn

--] CDN
local entity_provider = cdn.getProvider('entity')

--]] Settings
--]] Constants
--]] Variables
--]] Entity
local entity = {}
entity.__index = entity

function entity.new(id: string) : types.Entity
    local self = setmetatable({} :: types.self_entity, entity)

    assert(id, `Attempt to create a new entity with a nilset id!`)
    assert(type(id) == 'string', `Type mismatch for Argument 1, a {type(id)} was provided, but a string was expected.`)
    self.id = id

    assert(entity_provider:hasAsset(id), `Failed to find metadata for entity w/ provided id "{id}"`)
    local asset = entity_provider:getAsset(id)

    --] Define States
    self.fsm = fsm.create()

    self.idle = self.fsm:state('idle')
    self.patrol = self.fsm:state('patrol')

    self.fsm:switchState('idle')

    --] Rig
    self.rig = rig.new{
        id = id,
        model = asset.appearance.model,
        spawns = asset.behavior.spawn_points
    }

    return self
end

function entity:defineAnimation(state: string, animation_id: number)
    assert(animation_id, `:defineAnimation() missing animation_id!`)
    assert(type(animation_id) == 'number',
        `:defineAnimation() animation_id is of type {type(animation_id)}! It was expected to be a number`)

    local animation = Instance.new('Animation')
    animation.AnimationId = `rbxassetid://{animation_id}`

    self.rig.animator:defineAnimation(state, animation_id)
end

function entity:spawn(spawn_part: BasePart?)
    self.rig:spawn(spawn_part)
end

return entity