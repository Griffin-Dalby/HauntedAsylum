--[[

    Inventory Server Controller

    Griffin Dalby
    2025.09.17

    This script will control the server-sided inventory logic, saving &
    generating player data.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')

--]] Modules
local profileStore = require(replicatedStorage.Shared.ProfileStore)

local saved_template = require(script["template.saved"])
local session_template = require(script["template.session"])

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local players_cache = cache.findCache('players')
local persistent = players_cache:createTable('persistent') --> Persistent player data
local session = players_cache:createTable('session') --> Session-specific player data

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
local player_store = profileStore.New('PlayerStore', saved_template)
local profiles: {[Player]: typeof(player_store:StartSessionAsync())} = {}

function handlePlayerData(player: Player, profile: player_store.Profile<typeof(saved_template)>)
    persistent:setValue(player, profile)
    session:setValue(player, table.clone(session_template))
end

function loadPlayerData(player: Player)
    local profile = player_store:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= players
        end,
    })

    if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            profiles[player] = nil
            player:Kick(`Your session has expired; please rejoin.`)
        end)

        if player.Parent == players then
            profiles[player] = profile
            print(`Loaded data for player {player.Name}.{player.UserId}`)
            
            handlePlayerData(player, profile)
        else
            profile:EndSession()
        end
    else
        player:Kick(`Failed to load player data; please rejoin.`)
    end
end


for _, player in players:GetPlayers() do
    coroutine.wrap(function()
        loadPlayerData(player)
    end)()
end
players.PlayerAdded:Connect(loadPlayerData)
players.PlayerRemoving:Connect(function(player)
    local profile = profiles[player]
    if profile~=nil then
        profile:EndSession()
    end
end)