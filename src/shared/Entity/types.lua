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
    id: string,
    name: string,
    fsm: fsm_types.StateMachine,

    idle: fsm_types.SawdustState,
    patrol: fsm_types.SawdustState,
}
export type Entity = typeof(setmetatable({} :: self_entity, entity))

function entity.new() : Entity end

--[[ ENTITY RIG ]]--
local rig = {}
rig.__index = rig

export type RigData = {
    model: Model,
    animator: EntityAnimator
}

export type self_rig = {
    model: Model
}
export type EntityRig = typeof(setmetatable({} :: self_rig, rig))

--[[ ENTITY ANIMATOR ]]--
local animator = {}
animator.__index = animator

export type self_animator = {}
export type EntityAnimator = typeof(setmetatable({} :: self_animator, animator))

return __