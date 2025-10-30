--[[

    Objective Conditional

    Griffin Dalby
    2025.10.28

    This module will provide a interface to have dynamic conditions
    for objectives.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.Parent.types)
local util  = require(script.Parent.util)
local identity = require(script.identity)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local signal = sawdust.core.signal

--]] Settings
--]] Constants
--]] Variables
--]] Functions
function processSettings(condition_settings: types.ConditionSettings, check_condition: (identity: types.ConditionIdentity) -> nil)
    local proc_settings = {
        __desc = condition_settings.desc or '< no description >',
        __check = check_condition,
    }
    
    -- local proxy = newproxy(true)
    -- local meta = getmetatable(proxy)

    -- meta.__index = function(_, key)
    --     return proc_settings[key]
    -- end
    -- meta.__newindex = function(_, key, value)
    --     warn(`[{script.Name}] Attempt to index locked table ([{key}]={value})`)
    -- end

    -- meta.__metatable = 'locked'

    -- return proxy

    return proc_settings
end

--]] Module
local condition = {}
condition.__index = condition

function condition.new(condition_settings: types.ConditionSettings, check_condition: (identity: types.ConditionIdentity) -> nil):types.Condition
    -- util.sanitize.settings_condition(condition_settings)
    
    local self = setmetatable({}::types.self_condition, condition)

    --> Initalize
    self.__identity = identity.new()
    self.__env = processSettings(condition_settings, check_condition)

    --> Fill Values
    self.fulfillments = {}

    --> Signal
    local emitter = signal.new()

    self.fulfillment = emitter:newSignal() --> Conditions can fall in & out of fulfillment

    return self
end

function condition:update(player: Player): boolean
    local was_fulfilled = self.fulfillments[player]~=nil

    self.__identity:injectPlayer(player)
    local is_fulfilled = self.__env.__check(self.__identity)

    if is_fulfilled~=was_fulfilled then
        self.fulfillment:fire(player, is_fulfilled)

        if is_fulfilled then
            self.fulfillments[player] = true
        else self.fulfillments[player] = nil
        end
    end
    self.__identity:clearInjections()

    return is_fulfilled
end

return condition