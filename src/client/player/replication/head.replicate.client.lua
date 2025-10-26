--[[

    Head Orientation Replication

    Griffin Dalby
    2025.10.25

    This script will replicate head orientation for players.

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
local local_player = players.LocalPlayer
local local_userId = local_player.UserId

local max_head_turn = math.rad(35)
local root_joint_C0 = CFrame.new(0, 0, 0) * CFrame.Angles(-math.pi/2, 0, math.pi)

local smoothing = .1

--]] Constants

--]] Variables
local orientation_cache = {} :: {[number]: {}}
local player_cache = {} :: {[number]: Player}

local neck_cache = {}
local root_cache = {}

--]] Functions
function cachePlayer(userId: number): Player
    assert(not player_cache[userId], `Attempt to cache player ({userId}) twice!`)

    local player = players:GetPlayerByUserId(userId)
    assert(player, `Unable to locate player w/ ID {userId}`)

    player_cache[userId] = player
    return player
end

function updatePlayer(userId: number, look_direction: Vector3, body_yaw: number, delta: number)
    if userId==local_userId then return end

    --> Verify character
    local player: Player = player_cache[userId] or cachePlayer(userId)
    local character = player.Character
    if not character or not character.Head then return end

    local neck = character.Torso:FindFirstChild('Neck') :: Motor6D
    if not neck then return end

    local root = character:FindFirstChild('HumanoidRootPart') :: Part
    local root_joint = root:FindFirstChild('RootJoint') :: Motor6D
    if not root or not root_joint then return end

    local humanoid = character:FindFirstAncestorWhichIsA('Humanoid')
    if humanoid and humanoid.AutoRotate then
        humanoid.AutoRotate = false end

    --> Apply head rotation
    local body_rotation = CFrame.Angles(0, -body_yaw, 0)
    local adjusted_direction = body_rotation * look_direction
    local adjusted_cf = CFrame.lookAt(Vector3.zero, adjusted_direction)

    local target_neck_c0 = CFrame.new(0, 1, 0) * (adjusted_cf-adjusted_cf.Position) * CFrame.Angles(math.pi/2, math.pi, 0)
    local target_root_c0 = root_joint_C0 * CFrame.Angles(0, 0, body_yaw)

    if not neck_cache[userId] then
        neck_cache[userId] = neck.C0 end
    if not root_cache[userId] then
        root_cache[userId] = root_joint.C0 end

    local alpha = 1-math.exp(-smoothing*delta*60)

    neck_cache[userId] = neck_cache[userId]:Lerp(target_neck_c0, alpha)
    root_cache[userId] = root_cache[userId]:Lerp(target_root_c0, alpha)

    -- local current_root_angles = {root_cache[userId]:ToEulerAnglesYXZ()}
    -- local current_body_yaw = current_root_angles[3]

    -- local angle_diff = body_yaw-current_body_yaw
    -- angle_diff = (angle_diff+math.pi)%(2*math.pi)-math.pi

    -- local new_body_yaw = current_body_yaw+angle_diff*alpha
    -- root_cache[userId] = root_joint_C0*CFrame.Angles(0, 0, new_body_yaw)

    neck.C0 = neck_cache[userId]
    root_joint.C0 = root_cache[userId]
end

--]] Replication
mechanics_channel.head:route()
    :on('update', function(req, res)
        if not req.data[1] then
            warn(`[{script.Name}] Server updated with no cache provided!`)
            return end

        local string_cache = req.data[1]
        local new_cache = {}

        --> Convert string ID's into number ID's (Griffin-Dalby/Sawdust/issues/35)
        for id: string, vector: Vector3 in pairs(string_cache) do
            id = tonumber(id)

            if id==local_userId then continue end
            new_cache[id] = vector end
        
        orientation_cache = new_cache
    end)

--]] Logic
runService.RenderStepped:Connect(function(delta: number)
    for userId: number, look_data: {} in pairs(orientation_cache) do
        local lookDirection, bodyYaw = unpack(look_data)
        updatePlayer(userId, lookDirection, bodyYaw, delta)
    end
end)