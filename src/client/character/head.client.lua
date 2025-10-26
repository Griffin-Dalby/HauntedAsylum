--[[

    Character Head Replicator

    Griffin Dalby
    2025.10.26

    This script will replicate this player's head movements to the
    server.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local mechanics_channel = networking.getChannel('mechanics')

--]] Settings
local max_head_turn = math.rad(35)
local start_body_turn = math.rad(25)
local root_joint_C0 = CFrame.new(0, 0, 0) * CFrame.Angles(-math.pi/2, 0, math.pi)

--]] Constants
local camera = workspace.CurrentCamera

--> Index player
local player = players.LocalPlayer
local character = player.Character
local humanoid = character:FindFirstChildWhichIsA('Humanoid')

local root = character:WaitForChild('HumanoidRootPart') :: Part
local torso = character:WaitForChild('Torso') :: Part
local neck = torso:WaitForChild('Neck') :: Motor6D
local root_joint = root:WaitForChild('RootJoint') :: Motor6D

--]] Variables
local time_since_update = 0
local cumulative_yaw = 0
local current_body_yaw = 0
local last_yaw = 0

--]] Functions
function normalizeDelta(delta)
    if delta > math.pi then
        delta = delta-2*math.pi
    elseif delta < -math.pi then
        delta = delta+2*math.pi
    end
    return delta
end

--]] Replicator
humanoid.AutoRotate = false

runService.RenderStepped:Connect(function(deltaTime)
    if not neck then
        return end
    
    local camera_direction = root.CFrame:ToObjectSpace(camera.CFrame).LookVector.Unit
    local yaw = math.atan2(-camera_direction.X, -camera_direction.Z)
    
    local yaw_delta = normalizeDelta(yaw-last_yaw)
    cumulative_yaw = cumulative_yaw+yaw_delta
    last_yaw = yaw

    local head_yaw = cumulative_yaw-current_body_yaw
    local abs_head_yaw = math.abs(head_yaw)
    if abs_head_yaw > start_body_turn then
        local transition = (abs_head_yaw - start_body_turn) / (max_head_turn-start_body_turn)
        transition = math.clamp(transition, 0, 1)
        transition=transition*transition

        local target_body_yaw = cumulative_yaw-math.sign(head_yaw)*(start_body_turn+(max_head_turn-start_body_turn)*(1-transition))
        current_body_yaw = cumulative_yaw+(target_body_yaw-current_body_yaw)*(.15+transition*.15)
    end
    
    root_joint.C0 = root_joint_C0*CFrame.Angles(0, 0, current_body_yaw)

    --> Update Timer
    time_since_update+=deltaTime
    if time_since_update<.033 then
        return end
    time_since_update = 0

    mechanics_channel.head:with()
        :intent('update')
        :data(camera_direction, current_body_yaw)
        :fire()
end)