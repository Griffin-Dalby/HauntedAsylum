--[[

    Player Entity Senses

    Griffin Dalby
    2025.11.02

    This module will provide senses to make actions based off of player
    data.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local _entity_types = require(script.Parent.Parent.types)
local sense_types = require(script.Parent.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local players_cache = cache.findCache('players')
local session_cache = players_cache:createTable('session', true)

--]] Settings
--]] Constants
local is_server = runService:IsServer()

--]] Variables
--]] Functions
function findPathValue(t: {}, path: string)
    local split = path:split('.')
    local iter, iter_count = t, 0

    for _, v in ipairs(split) do
        iter=iter[v]; if iter==nil then break end
        iter_count+=1 end --> Iterate through the flag_name
    if iter==nil then
        warn(debug.traceback(`findPathValue() iterator hit nil @ {table.concat(split, '.', 1, iter_count)}`))
        return nil; end

    return iter
end

--]] Module

--> DAC Functions
type EntityCortex = sense_types.EntityCortex
local dac_meta = {
    sort = function(cortex: EntityCortex, t: {}, by_closest)
        --> Copy
        local sorted = {}
        for p, dist in pairs(t) do
            table.insert(sorted, {player=p, dist=dist})
        end

        --> Sort
        table.sort(sorted, function(a, b)
            return a.dist<b.dist
        end)

        return sorted
    end,
    closest = function(cortex: EntityCortex, t: {})
        local closest = {player=nil, dist=math.huge}
        for p, dist in pairs(t) do
            if dist>closest.dist then continue end
            closest = {player=p, dist=dist}
        end

        return closest
    end,
    enforceSDF = function(cortex: EntityCortex, t: {}, flag_name: string, expect_value: any)
        if not cortex.__settings or not cortex.__settings.player then 
            warn(debug.traceback(`DAC:enforceSDF() failed to locate cortex settings!`, 3))
            return end
        if is_server then
            for p: Player, dist in pairs(t) do
                --> Sanitize
                local p_session_data = session_cache:getValue(p)
                local aware_flags = cortex.__settings.player.sessionDataFlags
                if not table.find(aware_flags, flag_name) then
                    warn(debug.traceback(`DAC:enforceSDF() provided unscoped flag_name "{flag_name}"! No action taken.`))
                    break; end

                --> Search for flag
                local found_value = findPathValue(p_session_data, flag_name)

                if found_value~=expect_value then --> Drop
                    t[p]=nil end
            end
        else
            warn(debug.traceback(`DAC:enforceSDF() not implemented on client!`, 3))
        end

        return t
    end,
}

function newDataAugmentController(cortex: sense_types.EntityCortex)
    local dac = setmetatable({}, {
        __index = function(t, idx)
            local rget = rawget(t, idx)
            if rget then return rget end

            if dac_meta[idx] then
                return function(...)
                    return dac_meta[idx](cortex, t, ...)
                end 
            end

            return nil
        end
    })

    return dac
end

--> Sense Generator

return function(cortex: sense_types.EntityCortex) : sense_types.PlayerSense
    local sense = {} :: sense_types.self_sense_player
    setmetatable(sense, {__index = sense} :: sense_types.methods_sense_player)

    local settings = cortex.__settings.player

    --> Locate Players
    function sense:findPlayers()
        local raw_list, pop_list = players:GetPlayers(), {}

        for _, player: Player in pairs(raw_list) do
            local character = player.Character
            if not character
            or not character:FindFirstChild('Head')
            then continue end --> Not valid / no character

            local in_list = table.find(settings.blacklist, player)
            if (settings.filterType=='exclude' and in_list)
            or (settings.filterType=='include' and not in_list)
            then continue end --> Not valid according to blacklist/filter

            pop_list[player] = character
        end

        return pop_list
    end

    function sense:findPlayersInRadius(radius: number)
        if not cortex.__body or not cortex.__body.PrimaryPart then
            warn(debug.traceback(`[{script.Name}] My cortex reference is missing __body! Terminating with \{}`, 3))
            return {} end
        
        
        local raw_list, dac_list = self:findPlayers(), newDataAugmentController(cortex)
        local my_position = cortex.__body.PrimaryPart.Position

        for player: Player, character: Model in pairs(raw_list) do
            local root = character.PrimaryPart; if not root then continue end
            local dist = (my_position-root.Position).Magnitude
            if dist<=radius then
                dac_list[player] = dist
            end
        end

        return dac_list
    end

    function sense:adheresSDF(player: Player, flag_name: string, expect_value: any, expect_opposite: boolean?)
        --> Sanitize
        assert(session_cache:hasEntry(player), `Failed to find session data for player {player.Name}.{player.UserId}`)
        local p_session_data = session_cache:getValue(player)
        local aware_flags = (cortex.__settings.player or {sessionDataFlags = {}}).sessionDataFlags
        
        if not table.find(aware_flags, flag_name) then
            warn(debug.traceback(`PlayerSense:adheresSDF() provided unscoped flag_name "{flag_name}"! No action taken.`))
            return; end
        
        --> Search for flag
        local found_value = findPathValue(p_session_data, flag_name)
        return if expect_opposite then found_value~=expect_value else found_value==expect_value
    end

    function sense:getPlayerFromRoot(rootPart: BasePart)
        --> Sanitize & find character
        assert(rootPart, `[{script.Name}] :getPlayerFromRoot() missing argument 1! (rootPart: BasePart)`)
        local character = rootPart.Parent :: Model
        
        assert(character, `[{script.Name}] :getPlayerFromRoot() provided rootPart is parented to nil!`)
        if typeof(character) ~= 'Instance'
        or not character:IsA('Model')
        or not character:FindFirstChildWhichIsA('Humanoid') then
            warn(debug.traceback(`[{script.Name}] Provided rootPart ({rootPart:GetFullName()}) doesn't belong to a humanoid character!`))
            return; end

        --> Find player
        local player = players:GetPlayerFromCharacter(character)
        assert(character, `[{script.Name}] :getPlayerFromRoot() failed to find player from character ({character:GetFullName()})`)

        return player
    end

    function sense:getPlayerLookDirection(player: Player)
        local look_direction = {Vector3.new(0, 0, 1), 0}
        if session_cache:hasEntry(player) then
            local player_data = session_cache:getValue(player)
            look_direction = player_data.head_direction
        else
            warn(`[{script.Name}] Failed to locate Session Data for "{player.Name}#{player.UserId}"!`)    
        end

        return look_direction or {Vector3.new(0, 0, 1), 0}
    end

    --> TODO: Enforce SDF Functions

    return sense
end