--[[

    Objective Conditional Identity

    Griffin Dalby
    2025.10.28

    This module will provide a interface for the Identity found within
    conditionals.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.Parent.types)

--]] Sawdust
--]] Settings
local _debug = false

--]] Constants
--]] Variables
--]] Functions
--]] Module
local identity = {}
identity.__index = identity

function identity.new(): types.ConditionIdentity
    local self = {} :: types.self_condition_identity

    self.player = require(script['checks.player'])(self)
    self.asylum = require(script['checks.asylum'])(self)

    return setmetatable(self, identity)
end

--] Injections
function identity:injectPlayer(player: Player, override: boolean?)
    if _debug then
        print(`[{script.Name}] Injecting Player {player.Name} ({player.UserId})`) end
    
    if self.__player and not override then
        error(`[{script.Name}] Player already injected into Condition Identity! Use override to replace.`)
        return
    elseif self.__player and override then
        warn(`[{script.Name}] Overriding Player {self.__player.Name}:{self.__player.UserId} with {player.Name}:{player.UserId}`)
    end

    self.__player = player
end

function identity:clearInjections()
    self.__player = nil
end

return identity