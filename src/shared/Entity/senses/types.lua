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
export type SensePackages = {
    player: SensePlayerSettings?,
    physical: SensePhysicalSettings?,
    asylum: SenseAsylumSettings?,
}

export type methods_cortex = {
    __index: methods_cortex,
    
    injectRig: (self: EntityCortex, rig: {}) -> nil,
}

export type self_cortex = {
    __settings: SensePackages,
    __body: Model?,

    player: PlayerSense,
    physical: PhysicalSense,
    asylum: AsylumSense,
}
export type EntityCortex = typeof(setmetatable({} :: self_cortex, {} :: methods_cortex))

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
    
    ### `sort() -> { [number]: { player: Player, dist: number } }`
     Sorts the sense data from closest to furthest from the entity. 
     
    ### `closest() -> { player: Player, dist: number }`
     Provides the absolute closest player to the entity.
     
    ### `enforceSDF(flag_name: string, flag_value: any) -> player_DataAugmentController`
     Drops all players in the table that fail the SDF comparison.
    
    **flag_name: `string`**: The flag to check within the player's session data.<br>
    **flag_value: `any`**: What value to check against in order to determine success/failure
    
]]
export type player_DataAugmentController = {
    sort: ()->{[number]: {player: Player, dist: number}},
    closest: ()->{player: Player, dist: number},
    enforceSDF: (flag_name: string, flag_value: any)->player_DataAugmentController
}

export type methods_sense_player = {
    __index: methods_sense_player,

    findPlayer: (self: PlayerSense) -> {[Player]: Model},
    findPlayersInRadius: (self: PlayerSense, radius: number) -> {[Player]: number} & player_DataAugmentController,

    adheresSDF: (self: PlayerSense, player: Player, flag_name: string, expect_value: any) -> boolean,
    getPlayerFromRoot: (self: PlayerSense, root_part: BasePart) -> Player?,

    getPlayerLookDirection: (self: PlayerSense) -> {Vector3|number}
}
export type self_sense_player = {

}
export type PlayerSense = typeof(setmetatable({} :: self_sense_player, {} :: methods_sense_player))

--[[ PHYSICAL ]]--
--[[ This section covers the entity's physical senses, which allow
    easier spatial awareness, quick in-world lookups, and positioning
    data. ]]
export type SensePhysicalSettings = {
    
}

export type methods_sense_physical = {
    __index: sense_physical,

    getDiff: (self: PhysicalSense, point: Vector3) -> Vector3,
    getDistance: (self: PhysicalSense, point: Vector3) -> number,
    getDirection: (self: PhysicalSense, point: Vector3) -> Vector3,
}

export type self_sense_physical = {

}

export type PhysicalSense = typeof(setmetatable({} :: self_sense_physical, {} :: methods_sense_physical))

--[[ ASYLUM ]]--
--[[ This section covers the entity's asylum senses, which
    allow them to understand and interact with their surroundings
    easier. ]]
export type SenseAsylumSettings = {

}

export type methods_sense_asylum = {
    __index: methods_sense_asylum,

    Fetch: (id: string) -> (Part|Folder)?,
    GetFloor: (floor_id: number) -> Part?,
    GetRoom: (floor_id: number, room_id: string, specify: string?) -> Part?,

    GetConnectedRooms: (floor_id: number, room_id: string, section_id: string?) -> { [string]: Vector3 },
    GetSortedMappings: () -> {[number]: {[string]: {
        connections: { [string]: Vector3 },
        room: Instance?
    }}}
}

export type self_sense_asylum = {
    
}
export type AsylumSense = typeof(setmetatable({} :: self_sense_asylum, {} :: methods_sense_asylum))

return types