--[[

    Objective Interface Types

    Griffin Dalby
    2025.10.28

    Provides typechecking for the Objective interface.

--]]

local sawdust = require(game:GetService("ReplicatedStorage").Sawdust)

local __ = {}

--[[ CONDITION & IDENTITY ]]--

--> Identity
local identity_module = script.Parent.condition.identity
local player_checks = require(identity_module["checks.player"])

local condition_identity = {}
condition_identity.__index = condition_identity

export type self_condition_identity = {
    player: player_checks.PlayerChecks,
}
export type ConditionIdentity = typeof(setmetatable({}::self_condition_identity,condition_identity))

--> Conditional
local condition = {}
condition.__index = condition

export type ConditionSettings = {
    desc: string?,
}

export type self_condition = {
    __identity: ConditionIdentity,
    __env: { --> This table is immutable.
        __check: (identity: ConditionIdentity) -> boolean,
    },

    fulfillments: { [Player]: boolean? },

    fulfillment: sawdust.SawdustSignal,
}
export type Condition = typeof(setmetatable({}::self_condition,condition))

function condition.new(ConditionSettings: ConditionSettings, check: (identity: ConditionIdentity) -> boolean): Condition end

function condition:update(player: Player): boolean end

--[[ OBJECTIVE ]]--
local objective = {}
objective.__index = objective

export type ObjectiveSettings = {
    id: string,
    name: string,
    description: { short: string, long: string },

    conditions: { [number]: Condition }, --> [number] = Order of condition
    fulfilled: (is_fulfilled: boolean) -> string?, --> If string, find that objective & switch to it.
}

export type self_objective = {
    id: string,
    name: string,
    description: { short: string, long: string },

    conditions: { [number]: Condition },
    __fulfilled: (is_fulfilled: boolean) -> string?,

    completed: sawdust.SawdustSignal,
}
export type Objective = typeof(setmetatable(({}::self_objective),objective))

function objective.new() : Objective end

function objective:update(player: Player): boolean end

return __