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
local learn_types = require(script.Parent.learning.types)

local __ = {}

--[[ ENTITY OBJECT ]]--
export type methods_entity<TStEnv> = {
    __index: methods_entity<TStEnv>,
    new: (id: string, senses: sense_types.SensePackages) -> Entity<TStEnv>,

    defineAnimation: (self: Entity<TStEnv>, state: string, animation_id: number) -> nil,
    spawn: (self: Entity<TStEnv>, spawn_point: BasePart | Vector3) -> nil
}

export type self_entity<TStEnv> = {
    asset: entity_template.EntityTemplate,
    id: string,
    fsm: fsm_types.StateMachine<FSM_Cortex>,

    idle: fsm_types.SawdustState<FSM_Cortex, TStEnv>,
    chase: fsm_types.SawdustState<FSM_Cortex, TStEnv>,

    rig: EntityRig,
    nav: EntityNavigator,
}

export type Entity<TStEnv> = typeof(setmetatable({} :: self_entity<TStEnv>, {} :: methods_entity<TStEnv>))

--[[ ENTITY RIG ]]--
export type RigData = {
    id: string,
    model: Model,
    spawns: { BasePart }
}

export type methods_rig = {
    __index: methods_rig,

    new: (rig_data: RigData) -> EntityRig,
    spawn: (self: EntityRig, spawn_point: BasePart | Vector3) -> nil
}

export type self_rig = {
    model: Model,
    spawns: { BasePart },
    animator: EntityAnimator
}
export type EntityRig = typeof(setmetatable({} :: self_rig, {} :: methods_rig))

--[[ ENTITY ANIMATOR ]]--
export type methods_animator = {
    __index: methods_animator,

    new: () -> EntityAnimator,

    defineAnimation: (self: EntityAnimator, state: string, animation: Animation) -> nil
}

export type self_animator = {
    animations: {[string]: Animation}
}
export type EntityAnimator = typeof(setmetatable({} :: self_animator, {} :: methods_animator))

--[[ ENTITY NAVIGATOR ]]--
export type methods_navigator = {
    __index: methods_navigator,

    new: (rig: EntityRig) -> EntityNavigator
}

export type self_navigator = {
    rig: EntityRig,

    target: Player?,
}
export type EntityNavigator = typeof(setmetatable({} :: self_navigator, {} :: methods_navigator))

--[[ ENTITY METRICS ]]--
export type methods_metrics = {
    __index: methods_metrics,

    parseParameterUpdate: (parameters: { [string]: learn_types.LearningParameter }) -> nil
}

export type self_metrics = {
    parameter: {
        [number]: { [string]: number, } --> Track value of each parameter
    }
}
export type EntityMetrics = typeof(setmetatable({} :: self_metrics, {} :: methods_metrics))

--[[ FSM INJECTION ]]--
export type FSM_Cortex       = { 
    senses: sense_types.EntityCortex, 
    learn: learn_types.LearningModel, 
    metrics: EntityMetrics,
    
    target: BasePart? }
export type FSM_CortexInject = { environment: FSM_Cortex }
export type FSM_StateInject = { shared: FSM_Cortex }

return __