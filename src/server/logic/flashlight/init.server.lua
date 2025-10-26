--[[

    Flashlight Server-Side Logic

    Griffin Dalby
    2025.09.17

    This script will control the server-sided logic for flashlights

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local flashlight = require(replicatedStorage.Shared.Flashlight)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Caching
local players_cache = cache.findCache('players')

--]] Settings
--]] Constants

--]] Variables
--]] Functions
--]] Script
mechanics.flashlight:route()
    :on('init', function(req, res)
        local timeout = false
        task.delay(4, function()
            timeout = true end)
        local table = players_cache:findTable('session')

        repeat task.wait(0) until table:hasEntry(req.caller) or timeout
        if timeout and not table:hasEntry(req.caller) then
            warn(`[{script.Name}] Player "{req.caller.Name}.{req.caller.UserId}" couldn't be found in session data!`)
            res.reject('timeout')
            return end

        local player_session_data = players_cache:findTable('session'):getValue(req.caller)
        if player_session_data.flashlight then
            warn(`[{script.Name}] Player "{req.caller.Name}.{req.caller.UserId}" attempted to double initalize their flashlight!`)
            res.reject('cannot double initalize!')
            return end
        
        player_session_data.flashlight = flashlight.new(req.caller)
        res.send()
    end)
    :on('toggle', function(req, res)
        if req.data[1]==nil then
            res.reject('missing toggle_state')
            return end

        local player_session_data = players_cache:findTable('session'):getValue(req.caller)
        local p_flashlight = player_session_data.flashlight :: flashlight.Flashlight
        if not player_session_data.flashlight then
            warn(`[{script.Name}] Player "{req.caller.Name}.{req.caller.UserId}" attempted to toggle their flashlight, without an attached flashlight instance!`)
            res.reject('flashlight not initalized')
            return end
            
        local toggle_state = req.data[1]
        local success = p_flashlight:toggle(toggle_state)

        if success then
            res.data()
            res.send()

            mechanics.flashlight:with() --> Replicate state to clients
                :broadcastTo{req.caller}:setFilterType('exclude')
                :intent('replicate_state')
                :data(req.caller.UserId, toggle_state)
                :fire()
        else
            res.reject(p_flashlight.toggled)
        end
    end)