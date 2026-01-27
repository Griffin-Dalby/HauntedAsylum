--[[

    Head Event Endpoint

    Griffin Dalby
    2025.10.26

    This script will provide endpoints for Head orientation updates.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local Cache = sawdust.core.cache

--> Networking
local mechanics_channel = networking.getChannel('mechanics')

--> Cache
local players_cache = Cache.findCache('players')
local session_cache = players_cache:createTable('session', true)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
local cache = {} :: {[number]: Vector3}

--> Setup replicator
local time_since_update = 0
runService.Heartbeat:Connect(function(deltaTime)
    time_since_update+=deltaTime --> Timer
    if time_since_update<.066 then
        return end
    time_since_update = 0

    --> Send out update
    mechanics_channel.head:with()
        :broadcastGlobally()
        :intent('update')
        :data({cache})
        :fire()
end)

--> Setup endpoint
mechanics_channel.head:route()
    :on('update', function(req, res)
        local caller = req.caller

        local camera_direction = req.data[1] :: Vector3
        local body_yaw = req.data[2] :: number

        --> Validate Types
        if typeof(camera_direction)~='Vector3' then
            warn(`[{script.Name}] Player ({caller.Name}.{caller.UserId}) provided invalid camera_direction type: {typeof(camera_direction)}`)
            return end
        if type(body_yaw)~='number' then
            warn(`[{script.Name}] Player ({caller.Name}.{caller.UserId}) provided invalid body_yaw type: {type(body_yaw)}`)
            return end

        --> Validate Direction
        camera_direction = camera_direction.unit
        local direction_mag = camera_direction.Magnitude
        if direction_mag<.9 or direction_mag>1.1 then
            warn(`[{script.Name}] Player ({caller.Name}.{caller.UserId}) provided a invalid direction! (Magnitude: {direction_mag})`)
            return end

        --> Validate BodyYaw
        if body_yaw ~= body_yaw or math.abs(body_yaw) == math.huge then
            warn(`[{script.Name}] Player ({caller.Name}.{caller.UserId}) provided invalid body_yaw (NaN/Inf)`)
            return end
        -- if math.abs(body_yaw) > math.pi then
        --     warn(`[{script.Name}] Player ({caller.Name}.{caller.UserId}) provided excessive body_yaw: {body_yaw}`)
        --     return end
        
        --> Global Cache
        if session_cache:hasEntry(req.caller) then
            local player_cache = session_cache:getValue(req.caller)
            player_cache.head_direction = {camera_direction, body_yaw}
        else
            print('No session cache')
        end

        --> Local Cache
        cache[req.caller.UserId] = {camera_direction, body_yaw}
    end)

--> Player handling
players.PlayerRemoving:Connect(function(player)
    local player_id = player.UserId
    if cache[player_id] then
        cache[player_id] = nil
    end
end)