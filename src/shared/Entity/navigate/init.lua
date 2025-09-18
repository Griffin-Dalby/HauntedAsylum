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
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local navigator = {}
navigator.__index = navigator

function navigator.new(entity: types.Entity): types.EntityNavigator
    local self = setmetatable({} :: types.self_navigator, navigator)

    --] Setup Path
    local rig = entity.rig

    self.rig = rig
    self.path = simplePath.new(rig.model)
    self.path.Visualize = true

    self.goal_root = nil

    local function runPath()
        if not self.goal_root then return end
        self.path:Run(self.goal_root)
    end
    self.path.Blocked:Connect(runPath)
    self.path.WaypointReached:Connect(runPath)
    self.path.Error:Connect(runPath)
    self.path.Reached:Connect(runPath)

    --] Setup Logic
    local target_update_delta = 2
    self.targeter = runService.Heartbeat:Connect(function(dT)
        target_update_delta+=dT
        if target_update_delta<1 then return end
        target_update_delta = 0

        local targeted_root: BasePart = entity.asset.behavior.find_target(self.rig.model)
        self.goal_root = targeted_root
    end)

    local last_goal_root = nil
    self.walker = runService.Heartbeat:Connect(function(dT)
        if self.goal_root ~= last_goal_root then
            last_goal_root = self.goal_root
            runPath()
        end
    end)

    return self
end

function navigator:setTarget(player: Player?)
    self.player = player
end

return navigator