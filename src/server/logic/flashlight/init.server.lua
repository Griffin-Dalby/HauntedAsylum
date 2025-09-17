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
        local player_session_data = players_cache:findTable('session'):getValue(req.caller)
        assert(not player_session_data.flashlight,
            `Player ({req.caller.Name}.{req.caller.UserId}) attempted to double-init flashlight.`)
        
        player_session_data.flashlight = flashlight.new(req.caller)
    end)