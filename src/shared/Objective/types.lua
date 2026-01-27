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

export type methods_condition_identity = {
    __index: methods_condition_identity
}
export type self_condition_identity = {
    player: player_checks.PlayerChecks,
}
export type ConditionIdentity = typeof(setmetatable({}::self_condition_identity,{}::methods_condition_identity))

--> Conditional
export type ConditionSettings = {

    -- Description of the Condition
    desc: string?,
}

export type methods_condition = {
    __index: methods_condition,

    --[[
        Create a new Condition, which is used for Objectives to dynamically
        check if a part of an objective has completed, according to the check
        callback.

        @param ConditionSettings Settings for the Condition
        @param check Callback to check the condition, if it returns true this condition has been reached.
    ]]
    new: (ConditionSettings: ConditionSettings, check: (identity: ConditionIdentity) -> boolean) -> Condition,

    --[[
        Injects the player into the check identity, enabling the 
        player-specific checks within the identity.

        @param player Player to check
    ]]
    update: (self: Condition, player: Player) -> boolean,
}

export type self_condition = {
    __identity: ConditionIdentity,
    __env: { --> This table is immutable.
        __desc: string,
        __check: (identity: ConditionIdentity) -> boolean,
    },

    id: string,

    fulfillments: { [Player]: boolean? },
    fulfillment: sawdust.SawdustSignal<any>,
}
export type Condition = typeof(setmetatable({} :: self_condition, {} :: methods_condition))


--[[ OBJECTIVE ]]--
export type ObjectiveSettings = {
    id: string,
    name: string,
    description: { short: string, long: string },

    conditions: { [number]: Condition }, --> [number] = Order of condition
    fulfilled: (is_fulfilled: boolean) -> string?, --> If string, find that objective & switch to it.
}

export type methods_objective = {
    __index: methods_objective,

    --[[
        Creates a new objective with the provided settings.

        @param ObjectiveSettings Settings to use for composition

        @return Objective
    ]]
    new: (ObjectiveSettings: ObjectiveSettings) -> Objective,

    --[[
        Updates the objectives, checking all conditions, and only if all
        return true is it marked "completed"

        Once it is "completed", the completed event fires, and it always
        returns a boolean with the update status.

        @param player Player to check with conditions

        @return boolean Status of update
    ]]
    update: (self: Objective, player: Player) -> boolean,
}

export type self_objective = {
    id: string,
    name: string,
    description: { short: string, long: string },

    conditions: { [number]: Condition },
    __fulfilled: (is_fulfilled: boolean) -> string?,

    completed: sawdust.SawdustSignal<any>,
}
export type Objective = typeof(setmetatable({} :: self_objective, {} :: methods_objective))

return __