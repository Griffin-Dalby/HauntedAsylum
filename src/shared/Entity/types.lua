--[[

    Entity Object Types

    Griffin Dalby
    2025.09.15

    This module holds all type definitions for the Entity object.

--]]

local sawdust = game:GetService('ReplicatedStorage').Sawdust
local fsm_types = require(sawdust.__impl.states.types)

local __ = {}

--[[ ENTITY OBJECT ]]--
local entity = {}
entity.__index = entity

export type self_entity = {
    asset: {},
    id: string,
    fsm: fsm_types.StateMachine,

    idle: fsm_types.SawdustState,
    patrol: fsm_types.SawdustState,

    rig: EntityRig,
    nav: EntityNavigator,
}
export type Entity = typeof(setmetatable({} :: self_entity, entity))

function entity.new() : Entity end
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

return __