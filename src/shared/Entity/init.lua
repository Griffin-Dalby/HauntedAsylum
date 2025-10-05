--[[

    Entity Object

    Griffin Dalby
    2025.09.15

    This module will provide a basic entity object, which can be easily used to
    compile new entities and use similar or create new behavior patterns.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')

--]] Module
local types = require(script.types)
local rig = require(script.rig)
local nav = require(script.navigate)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local fsm = sawdust.core.states
local cdn = sawdust.core.cdn

--] Networking
local world_channel = networking.getChannel('world')

--] CDN
local entity_provider = cdn.getProvider('entity')

--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Entity
local entity = {}
entity.__index = entity

--[[ entity.new(id: string) : Entity
    Constructor function for the entity object, which will locate
    the entity's asset data and build behaviors and appearance.
    This will provide a FSM, rig & animation controller, and
    a pathfinding / navigation system. ]]
function entity.new(id: string) : types.Entity
    local self = setmetatable({} :: types.self_entity, entity)

    assert(id, `Attempt to create a new entity with a nilset id!`)
    assert(type(id) == 'string', `Type mismatch for Argument 1, a {type(id)} was provided, but a string was expected.`)
    self.id = id

    assert(entity_provider:hasAsset(id), `Failed to find metadata for entity w/ provided id "{id}"`)
    self.asset = entity_provider:getAsset(id)

    --] Define States
    self.fsm = fsm.create()

    self.idle = self.fsm:state('idle')
    self.chase = self.fsm:state('chase')

    self.idle:transition('chase'):when(function(env) return env.shared.target~=nil end)
    self.chase:transition('idle'):when(function(env) return env.shared.target==nil end)

    self.fsm:switchState('idle')

    if not is_client then
        --] Rig
        self.rig = rig.new{
            id = id,
            model = self.asset.appearance.model,
            spawns = self.asset.behavior.spawn_points
        }
        self.nav = nav.new(self)
    else
        --] Replication
        world_channel.entity:route()
            :on('target', function(req)
                if req.data[1]~=id then return end
                self.fsm.environment.target = req.data[2] end)
    end

    return self
end

--[[ entity:defineAnimation(state: string, animation_id: number)
    This will create an animation based off the animation id, and attach
    it to the animation system, where it'll automatically play when
    the state that's defined is active in the state manager. ]]
function entity:defineAnimation(state: string, animation_id: number)
    assert(animation_id, `:defineAnimation() missing animation_id!`)
    assert(type(animation_id) == 'number',
        `:defineAnimation() animation_id is of type {type(animation_id)}! It was expected to be a number`)

    local animation = Instance.new('Animation')
    animation.AnimationId = `rbxassetid://{animation_id}`

    self.rig.animator:defineAnimation(state, animation_id)
end

--[[ entity:spawn(spawn_part: BasePart?)
    This will spawn this entity either at the specified base_part,
    or at one of the random specified ones. ]]
function entity:spawn(spawn_part: BasePart?)
    self.rig:spawn(spawn_part)
end

return entity