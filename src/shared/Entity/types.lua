--!nocheck
--[[

    Entity Object Types

    Griffin Dalby
    2025.09.15

    This module holds all type definitions for the Entity object.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local sawdust = replicatedStorage.Sawdust

local entity_template = require(replicatedStorage.Content.entity.__entity)
local fsm_types = require(sawdust.__impl.states.types)
local sense_types = require(script.Parent.senses.types)

local __ = {}

--[[ ENTITY OBJECT ]]--
local entity = {}
entity.__index = entity

export type self_entity<TStEnv> = {
    asset: entity_template.EntityTemplate,
    id: string,
    fsm: fsm_types.StateMachine<FSM_Cortex, TStEnv>,

    idle: fsm_types.SawdustState<FSM_Cortex, TStEnv>,
    chase: fsm_types.SawdustState<FSM_Cortex, TStEnv>,

    rig: EntityRig,
    nav: EntityNavigator,
}

export type Entity<TStEnv> = typeof(setmetatable({} :: self_entity<TStEnv>, entity))

function entity.new(id: string, senses: sense_types.SensePackages) end
function entity:defineAnimation(state: string, animation_id: number) end
function entity:spawn(spawn_part: BasePart?) end

--[[ ENTITY RIG ]]--
local rig = {}
rig.__index = rig

export type RigData = {
    id: string,
    model: Model,
    spawns: { BasePart }
}

export type self_rig = {
    model: Model,
    spawns: { BasePart },
    animator: EntityAnimator
}
export type EntityRig = typeof(setmetatable({} :: self_rig, rig))

function rig.new(rig_data: RigData) : EntityRig end
function rig:spawn(spawn_part: BasePart?) end

--[[ ENTITY ANIMATOR ]]--
local animator = {}
animator.__index = animator

export type self_animator = {
    animations: {[string]: Animation}
}
export type EntityAnimator = typeof(setmetatable({} :: self_animator, animator))

function animator.new() : EntityAnimator end
function animator:defineAnimation(state: string, animation: Animation) end

--[[ ENTITY NAVIGATOR ]]--
local navigator = {}
navigator.__index = navigator

export type self_navigator = {
    rig: EntityRig,

    target: Player?,
}
export type EntityNavigator = typeof(setmetatable({} :: self_navigator, navigator))

function navigator.new(rig: EntityRig) : EntityNavigator end

--[[ ENTITY LEARNING & SENSES ]]--
local learning = {}
learning.__index = learning

--[[ LearningParameter
    This table provides the values needed to detail the baseline of a
    parameter, and the upper/lower limits of knowledge.
    
    [parameter]: {default, limits: {min, max}}
    ['curiosity']: {def=.2, lim={min=.1, max=.85}}
    
    These parameters are then parsed in the entities behaviorial charting. ]]
export type LearningParameter = { 
    def: number,
    lim: {min: number, max: number},
    adj: (...any) -> number }
export type LearningParameters = {
    [string]: LearningParameter,
}

export type self_learning = {
    parameters: LearningParameters
}
export type EntityLearning = typeof(setmetatable({} :: self_learning, learning))

function learning.new() : EntityLearning end

export type FSM_Cortex       = { senses: sense_types.EntityCortex, learn: EntityLearning, target: BasePart? }
export type FSM_CortexInject = { environment: FSM_Cortex }
export type FSM_StateInject = { shared: FSM_Cortex }

return __