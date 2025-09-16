--[[

    Entity Object Types

    Griffin Dalby
    2025.09.15

    This module holds all type definitions for the Entity object.

--]]

local sawdust = require(game:GetService('ReplicatedStorage').Sawdust)
local fsm = sawdust.core.states

local __ = {}

--[[ ENTITY OBJECT ]]--
local entity = {}
entity.__index = entity

export type self_entity = {
    id: string,
    name: string,
    fsm: fsm.StateMachine
}
export type Entity = typeof(setmetatable({} :: self_entity, entity))

function entity.new() : Entity end

return __