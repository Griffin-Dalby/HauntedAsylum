--[[

    Interactions Logic

    Griffin Dalby
    2025.09.09

    This script will process client interaction requests and run the
    according logic.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local __secure = require(script.secure)

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

local secure = __secure.new()