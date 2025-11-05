--!nocheck
--[[

    Entity Senses Types

    Griffin Dalby
    2025.11.02

    This module will provide types for the entity senses, which will
    cover the DSL-like language that powers the entity behavior system.

--]]

local types = {}

--[[$ CORTEX $]]--
--[[ This section covers the entities cerebral cortex, basically the
    link between all of the senses in the DSL making it easy to access
    each sense.
    
    Internally it's hooked into the FSM environment with cortex.hook(),
    however that's intentionally omitted from this type definition. ]]
local cortex = {}
cortex.__index = cortex

export type SensePackages = {
    player: SensePlayerSettings?,
    physical: SensePhysicalSettings?,
}

export type self_cortex = {
    __settings: SensePackages,
    __body: Model?,

    player: PlayerSense,
    physical: PhysicalSense
}
export type EntityCortex = typeof(setmetatable({} :: self_cortex, cortex))

function cortex:injectRig(rig: {}) end

--[[ PLAYER ]]--
--[[ This section covers the entity's player senses, which make it
    really easy to locate players with patterns, and filter with
    chaining logic. ]]
local sense_player = {}
sense_player.__index = sense_player

export type SensePlayerSettings = {
    filterType: 'exclude'|'include'|nil,
    blacklist: {Player}?,
    sessionDataFlags: {string}?,
}

--[[ 
    Metamethod injection that provides abstractions for data found
    in the player sense.
    
    ### sort`() -> { [number]: { player: Player, dist: number } }`
     Sorts the sense data from closest to furthest from the entity. 
     
    ### closest`() -> { player: Player, dist: number }`
     Provides the absolute closest player to the entity.
     
    ### enforceSDF`(flag_name: string, flag_value: any) -> DataAugmentController`
     Drops all players in the table that fail the SDF comparison.
    
    **flag_name: `string`**: The flag to check within the player's session data.<br>
    **flag_value: `any`**: What value to check against in order to determine success/failure
    
]]
export type DataAugmentController = {
    sort: ()->{[number]: {player: Player, dist: number}},
    closest: ()->{player: Player, dist: number},
    enforceSDF: (flag_name: string, flag_value: any)->DataAugmentController
}

export type self_sense_player = {

}
export type PlayerSense = typeof(setmetatable({} :: self_sense_player, sense_player))

function sense_player:findPlayers()
    : {[Player]: Model} end
function sense_player:findPlayersInRadius(radius: number)
    : {[Player]: number} & DataAugmentController end --> Inject DAC

function sense_player:adheresSDF(player: Player, flag_name: string, expect_value: any)
    : boolean end
function sense_player:getPlayerFromRoot(rootPart: BasePart)
    : Player? end
-- function sense_player:findPlayersInArea(area: Part)
--     : {[Player]: Model} end

--[[ PHYSICAL ]]--
--[[ This section covers the entity's physical senses, which allow
    easier spatial awareness, quick in-world lookups, and positioning
    data. ]]
local sense_physical = {}
sense_physical.__index = sense_physical

export type SensePhysicalSettings = {

}

export type self_sense_physical = {

}
export type PhysicalSense = typeof(setmetatable({}, sense_physical))

function sense_physical:getDiff(point: Vector3) : Vector3 end
function sense_physical:getDistance(point: Vector3) : number end
function sense_physical:getDirection(point: Vector3) : Vector3 end

return types