--[[

    Objective Condition Tester

    Griffin Dalby
    2025.10.29

    This module will provide a testing system to prevent faulty conditions
    which could cause runtime issues.

    ** This is an internal module! Unexposed (globally) to types.lua. **

--]]

--]] Services
--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
--]] Settings
local __debug = false

--]] Constants
--]] Variables
--]] Functions
--]] Module
local dummy_player = {
    Name = 'ConditionTesterDummy',
    UserId = 0,
}

local tester = {}
tester.__index = tester

type self = {}
export type ConditionTester = typeof(setmetatable({} :: self, tester))

function tester.new() : ConditionTester
    local self = setmetatable({} :: self, tester)

    return self
end

function tester:runTest(condition: types.Condition): (boolean, string?)
    condition.__identity:injectPlayer(dummy_player)
    local success, result = pcall(function()
        return condition.__env.__check(condition.__identity)
    end)
    condition.__identity:clearInjections()

    if not success then
        return false, `Condition check failed: {result}`
    end

    if type(result) ~= 'boolean' then
        return false, `Condition check did not return boolean (returned {type(result)})`
    end

    return true, nil
end

function tester:runTests(conditions: {types.Condition})
    for order: number, condition in pairs(conditions) do
        print(condition)
        if __debug then
            print(`[{script.Name}] Testing Condition @ {order}`) end

        local success, err = self:runTest(condition)
        assert(success, `[ConditionTester] Test Failed for Condition ID [{order}]:\n    {err}`)
    end
end

return tester