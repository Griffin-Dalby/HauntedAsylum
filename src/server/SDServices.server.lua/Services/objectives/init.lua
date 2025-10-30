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
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local builder = sawdust.builder
local cache = sawdust.core.cache

--> Cache
local players_cache = cache.findCache('players')
local session = players_cache:createTable('session', true)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local update_interval = 3/60
local elapsed = 0

local objectives_service = builder.new('objectives')
    :loadMeta(script.meta)
    :init(function(self, deps)
        print(self)
        --> Initalize Chapters
        self.chapter = {
            intro = self.meta.intro(),
        }
    end)

    :method('prepare_player', function(self, player: Player)
        local player_session = session:getValue(player)

        player_session.current_objective = self.chapter.intro[1]
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