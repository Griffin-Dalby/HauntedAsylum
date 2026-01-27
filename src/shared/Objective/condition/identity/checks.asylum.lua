--[[

    Asylum Condition Checks

    Griffin Dalby
    2026.1.27

    This module provides abstracted checks for the asylum, allowing dynamic
    room detection.

]]

--]] Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--]] Modules
--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)
local SawSvc = Sawdust.services

--]] Module

--> Define Type
type self_fields = {
    __index: self_fields
}

type self_methods = {

}
export type AsylumChecks = typeof(setmetatable({} :: self_methods, {} :: self_fields))

--> Check Generator
return function(identity: {}) : AsylumChecks
    local checks = {} :: self_methods
    setmetatable(checks, {__index = identity})

    --> Verifications
    function checks:_verify_injections()
        local player = self.__player :: Player?
        assert(player, `[{script.Name}] missing player injection!`)

        return player
    end

    --> Check Methods
    local AsylumSvc
    local function GetAsySvc()
        if AsylumSvc then return end
        AsylumSvc = SawSvc:getService("asylum") :: Sawdust.SawdustService & {
            player_stats: {
                [Player]: {
                    current_room: string,
                    current_floor: string,
                }
            }
        }
    end

    function checks:inRoom(room_id: string)
        if not AsylumSvc then
            GetAsySvc()
            if not AsylumSvc then return false end
        end

        local player = self:_verify_injections()
        
        local player_stats = AsylumSvc.player_stats[player]
        if not player_stats then print("No player stats") return false end

        return player_stats.current_room==room_id
    end

    function checks:onFloor(floor_id: number)
        if not AsylumSvc then
            GetAsySvc()
            if not AsylumSvc then return false end
        end

        local player = self:_verify_injections()
        
        local player_stats = AsylumSvc.player_stats[player]
        if not player_stats then print("No player stats") return false end

        return player_stats.current_floor==floor_id
    end

    return checks
end