--[[

    Objectives SDService

    Griffin Dalby
    2025.10.15

    This module will provide behavior for Objectives on the server-side
    utilizing Sawdust Services.

    Specifically, it loads each "chapter" from the meta, and then generates
    them into usable objectives, which link together cohesively.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local Objective = require(replicatedStorage.Shared.Objective)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local builder = sawdust.builder
local cache = sawdust.core.cache

--> Networking
local GameChannel = networking.getChannel('game')

--> Cache
local players_cache = cache.findCache('players')
local session = players_cache:createTable('session', true)

--]] Settings
local update_interval = 3/60

--]] Constants
--]] Variables
local elapsed = 0

--]] Functions
--]] Module
local objectives_service = builder.new('objectives')
    :dependsOn('asylum')
    
    :loadMeta(script.meta)
    :init(function(self, deps)
        --> Initalize Chapters
        self.chapter = {
            intro = self.meta.intro(),
        }
    end)

    :method('prepare_player', function(self, player: Player)
        local player_session = session:getValue(player)

        player_session.current_objective = self.chapter.intro[1]
        
        if not player.Character then player.CharacterAdded:Wait() end
        
        local batched = Objective.batchObjective( player_session.current_objective )
        print(batched)

        task.wait(.25)
        GameChannel.objective:with()
            :broadcastTo(player)
            :intent('new')
            :data( batched )
            :fire()
    end)
    :start(function(self)
        runService.Heartbeat:Connect(function(dt)
            --> Timer
            elapsed+=dt
            if elapsed<update_interval then return end
            elapsed = 0

            --> Run Updates
            for _, player in players:GetPlayers() do
                if not session:hasEntry(player) then continue end

                local player_session = session:getValue(player)
                local current_objective = player_session.current_objective

                if current_objective~=nil then
                    local completed = current_objective:update(player)
                else
                    self.prepare_player(player)
                end
            end
        end)
    end)

return objectives_service