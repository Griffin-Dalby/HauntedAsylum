--[[

    Entity Navigation Module

    Griffin Dalby
    2025.09.18

    This module will provide logic for entity navigation, utilized
    mostly during chases

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')

--]] Modules
local types = require(script.Parent.types)

local simplePath = require(replicatedStorage.Shared.SimplePath)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking channels
local world_channel = networking.getChannel('world')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local navigator = {}
navigator.__index = navigator

--[[ navigator.new(entity: Entity)
    Constructor function for the navigator system that generates a path
    and the logic to search and walk towards a target based off of the
    entities behaviorial patterns. ]]
function navigator.new(entity: types.Entity<types.FSM_Cortex>): types.EntityNavigator
    local self = setmetatable({} :: types.self_navigator, navigator)

    --] Setup Path
    local rig = entity.rig

    self.rig = rig
    self.path = simplePath.new(rig.model, {
        AgentWidth = 2,
        AgentHeight = 3,
    })
    self.path.Visualize = false

    self.nav_target = nil

    local function runPath()
        if not self.nav_target then return end
        self.path:Run(self.nav_target)
    end
    self.path.Blocked:Connect(runPath)
    self.path.WaypointReached:Connect(runPath)
    self.path.Error:Connect(runPath)
    self.path.Reached:Connect(runPath)

    --] Setup Logic
    self.walker = runService.Heartbeat:Connect(function(dT)
        local c_target = entity.fsm.environment.target
        
        if (self.nav_target ~= nil) --> Target switch to nil
                and (c_target==nil) 
                and (self.path._status ~= 'Idle') then
            self.nav_target = nil
            world_channel.entity:with()
                :broadcastGlobally()
                :intent('target')
                :data(entity.id, nil)
                :fire()

            self.path:Stop()
        end

        if self.nav_target ~= c_target then --> Target switch
            world_channel.entity:with()
                :broadcastGlobally()
                :intent('target')
                :data(entity.id, self.nav_target)
                :fire()

            self.nav_target = c_target
            runPath()
        end
    end)

    return self
end

return navigator