--[[

    Interaction Event Endpoints

    Griffin Dalby
    2025.09.10

    This script provides Endpoints for interaction networking
    events.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local world_channel = networking.getChannel('world')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script

local auth_handler = {
    ['object'] = function(req, res)
        
        return true
    end,

    ['prompt'] = function()
        
        return true
    end
}

world_channel.interaction:route()
    :on('auth', function(req, res)
        local auth_type = req.data[1]
        if not auth_type or type(auth_type)~="string"
            or not auth_handler[auth_type] then
            res.reject(`Invalid auth_type!`); return end

        res.data(auth_handler[auth_type](req))
        res.send()
    end)