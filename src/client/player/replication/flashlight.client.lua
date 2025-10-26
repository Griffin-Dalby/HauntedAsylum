--[[

    Flashlight Replication

    Griffin Dalby
    2025.10.25

    This script will replicate flashlight usage between players.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')

--]] Modules
local flashlight = require(replicatedStorage.Shared.Flashlight)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local mechanics_channel = networking.getChannel('mechanics')

--]] Settings
--]] Constants
local replicated_flashlights = {} :: {[Player]: flashlight.Flashlight}

--]] Variables
--]] Functions
function initalizeReplicateFlashlight(player: Player) : flashlight.Flashlight
    --> Sanitize & Initalize
    assert(not replicated_flashlights[player], `Player ({player.Name}.{player.UserId}) already has a ReplicatedFlashlight instance!`)
    local r_flashlight = flashlight.new(player)

    replicated_flashlights[player] = r_flashlight
    return r_flashlight
end

--]] Script
mechanics_channel.flashlight:route()
    :on('replicate_state', function(req, res)
        local r_player_id:number, r_state:boolean = unpack(req.data)
        local r_player = players:GetPlayerByUserId(r_player_id)
        assert(r_player, `Unable to locate player ({r_player_id}) to toggle flashlight state!`)

        local r_flashlight = replicated_flashlights[r_player]
        if not r_flashlight then
            r_flashlight = initalizeReplicateFlashlight(r_player)
        end

        r_flashlight.toggled = r_state
    end)

players.PlayerAdded:Connect(initalizeReplicateFlashlight)
for _, player in pairs(players:GetPlayers()) do
    if player==players.LocalPlayer then continue end
    initalizeReplicateFlashlight(player) end