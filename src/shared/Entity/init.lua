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
local senses, sense_types = require(script.senses), require(script.senses.types)
local learn = require(script.learning)
local rig = require(script.rig)
local nav = require(script.navigate)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local fsm = sawdust.core.states; local fsm_type = require(replicatedStorage.Sawdust.__impl.states.types)
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

--> Forward Exports
export type FSM_Cortex       = types.FSM_Cortex
export type FSM_CortexInject = types.FSM_CortexInject

export type Entity<TStEnv> = types.Entity<TStEnv>

--> Functions

--[[ entity.new(id: string, sense_packages: {[string]: {}}) : Entity
    Constructor function for the entity object, which will locate
    the entity's asset data and build behaviors and appearance.
    This will provide a FSM, rig & animation controller, a
    pathfinding / navigation system, with simple "senses".
    
    These senses can be disabled or enabled as needed, and you
    can change settings for each sense. ]]
function entity.new<TStEnv>(id: string, sense_packages: sense_types.SensePackages, learn_params: types.LearningParameters) : Entity<TStEnv>
    local self = setmetatable({} :: types.self_entity<TStEnv>, entity)

    assert(id, `Attempt to create a new entity with a nilset id!`)
    assert(type(id) == 'string', `Type mismatch for Argument 1, a {type(id)} was provided, but a string was expected.`)
    self.id = id

    assert(entity_provider:hasAsset(id), `Failed to find metadata for entity w/ provided id "{id}"`)
    self.asset = entity_provider:getAsset(id)

    --] Define States
    self.fsm = fsm.create() :: fsm_type.StateMachine<FSM_Cortex>
    senses.hook(self, sense_packages)
    learn.hook(self, learn_params)

    self.idle = self.fsm:state('idle')   :: fsm_type.SawdustState<FSM_Cortex, TStEnv>
    self.chase = self.fsm:state('chase') :: fsm_type.SawdustState<FSM_Cortex, TStEnv>

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
        self.fsm.environment.senses.injectRig(self.rig)
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