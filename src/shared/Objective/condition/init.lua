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
function processSettings(condition_settings:types.ConditionSettings)
    local proc_settings = {
        __check = condition_settings.check,
    }
    
    local proxy = newproxy(true)
    local meta = getmetatable(proxy)

    meta.__index = function(_, key)
        return proc_settings[key]
    end
    meta.__newindex = function(_, key, value)
        warn(`[{script.Name}] Attempt to index locked table ([{key}]={value})`)
    end

    meta.__metatable = 'locked'

    return proxy
end

--]] Module
local condition = {}
condition.__index = condition

function condition.new(condition_settings:types.ConditionSettings):types.Condition
    util.sanitize.settings_condition(condition_settings)
    
    local self = setmetatable({}::types.self_condition, condition)

    --> Initalize
    self.identity = identity.new(self)
    self.__env = processSettings(condition_settings)

    --> Fill Values
    self.fulfilled = false

    --> Signal
    local emitter = signal.new()

    self.fulfillment = emitter:newSignal()

    return self
end

function condition:update()
    local was_fulfilled = self.fulfilled
    self.fulfilled = self.__env.__check(self.identity)

    if self.fulfilled~=was_fulfilled then
        self.fulfillment:fire(self.fulfilled)
        
    end
end

return condition