--!nocheck
--[[

    Player Condition Checks

    Griffin Dalby
    2025.10.29

    This module will provide some abstracted checks for the player specifically,
    providing a robust identity interface.

--]]

--]] Services
--]] Modules
--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module

--> Define Type
local _checks = {}
_checks.__index = _checks

type self = {}
export type PlayerChecks = typeof(setmetatable({}::self, _checks))

function _checks:inArea(area: Part): boolean end

--> Check Generator (For inheritance)
return function(identity: {}) : PlayerChecks
    local checks = {}
    setmetatable(checks, {__index = identity})

    function checks:_verify_injections()
        local player = self.__player :: Player?
        assert(player, `[{script.Name}] PlayerChecks missing player injection!`)

        return player
    end

    function checks:inArea(area: Part): boolean
        local player = self:_verify_injections()
        
        if not area then
            warn(debug.traceback(`[{script.Name}] :inArea() missing area argument!`, 3))
            return false end

        local character = player.Character; if not character then return false end

        local olapParams = OverlapParams.new()
        olapParams.FilterType = Enum.RaycastFilterType.Include
        olapParams.FilterDescendantsInstances = {character}

        local partsInArea = workspace:GetPartsInPart(area, olapParams)

        return player.Character and #partsInArea > 0
    end

    return checks
end