--[[

    Hiding Event Endpoints

    Griffin Dalby
    2025.10.17

    This script provides endpoints for hiding in things.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Cache
local players_cache = cache.findCache('players')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
function pTag(p: Player)
    return `{p.Name}.{p.UserId}` end

--]] Script
mechanics.hiding:route()
    :on('exit_locker', function(req, res)
        local player = req.caller

        local session_data = players_cache:findTable('session'):getValue(req.caller)
        local is_hiding = session_data.is_hiding
        if not is_hiding then
            error(`[{script.Name}] Player {player.Name}.{player.UserId} is already hiding!`)
            return end

        local character = player.Character
        local humanoid  = character.Humanoid
        local root_part = humanoid.RootPart

        local locker_model = is_hiding[1].Parent.Parent :: Model
        local body = locker_model['Door']['Body'] :: Part

        task.delay(1, function()
            body:SetNetworkOwner(nil)
        end)
        root_part.Anchored = false
        -- root_part.CFrame = is_hiding[2]

        session_data.is_hiding = false
    end)
 