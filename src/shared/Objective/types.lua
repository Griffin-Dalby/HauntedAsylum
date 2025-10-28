--[[

    Objective Interface Types

    Griffin Dalby
    2025.10.28

    Provides typechecking for the Objective interface.

--]]

local __ = {}

--[[ CONDITION & IDENTITY ]]--
local condition = {}
condition.__index = condition

export type ConditionSettings = {
    check: (env: {}) -> boolean,
}

export type self_condition = {
    __env: { --> This table is locked.
        __check: (identity: ConditionIdentity) -> boolean,
    },

    
}
export type Condition = typeof(setmetatable({}::self_condition,condition))

function condition.new(): Condition end

local condition_identity = {}
condition_identity.__index = condition_identity

export type self_condition_identity = {

}
export type ConditionIdentity = typeof(setmetatable({}::self_condition_identity,condition_identity))

function condition_identity.new(): ConditionIdentity end

--[[ OBJECTIVE ]]--
local objective = {}
objective.__index = objective

export type ObjectiveSettings = {
    id: string,
    conditions: { [number]: Condition }, --> [number] = Order of condition

}

export type self_objective = {}
export type Objective = typeof(setmetatable(({}::self_objective),objective))

function objective.new() : Objective end

return __