--[[

    Camera Controller Module

    Griffin Dalby
    2025.09.16

    This provides the required runtimes for the Camera systems & behavior.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local userInputs = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local movement_cache = cache.findCache('movement')

--]] Settings
local mouse_sensitivity = .4
local gamepad_sensitivity = 3
local thumbstick_deadzone = .15

local bob_freq = 4                         --] Bob cycle speed

local s_bob_ampl, w_bob_ampl = 1.25, .1    --] Bob intensity
local s_tilt_ampl, w_tilt_ampl = 1.5, .5   --] Side-to-side movement
local s_horiz_sway, w_horiz_sway = 1.2, .4 --] Cam roll/tilt in degs

--]] Constants
--]] Variables
--]] Funtions
--]] Module
local camera = {}
camera.__index = camera

type self = {
    camera: Camera,
    runtime: RBXScriptConnection,

    camera_offset: Vector3,
    camera_angles: Vector2,
}
export type CameraController = typeof(setmetatable({} :: self, camera))

function camera.init(env: {}) : CameraController
    local self = setmetatable({} :: self, camera)

    local player = players.LocalPlayer

    local character: Model, humanoid: Humanoid
    local head: BasePart
    local function fetchCharacter()
        assert(player.Character, `Failed to fetch character for camera controller!`)
        character = player.Character
        humanoid = character:WaitForChild('Humanoid')
        head = character:WaitForChild('Head')
    end

    self.camera_offset = Vector3.new(0, 0, 0)
    self.camera_angles = Vector2.new(0, 0)
    local last_input_type = 'KBM'
    
    local thumbstick
    self.mouse_capture = userInputs.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        last_input_type='KBM'

        local delta = input.Delta
        self.camera_angles = self.camera_angles + Vector2.new(
            -delta.Y * mouse_sensitivity,
            -delta.X * mouse_sensitivity
        )
        self.camera_angles = Vector2.new(
            math.clamp(self.camera_angles.X, -80, 80),
            self.camera_angles.Y
        )
    end)

    self.thumb_capture = runService.RenderStepped:Connect(function(dt)
        local inputs = userInputs:GetGamepadState(Enum.UserInputType.Gamepad1)
        if not inputs then return end

        local delta = Vector2.zero

        for _, input in ipairs(inputs) do
            if input.KeyCode == Enum.KeyCode.Thumbstick2 then
                delta = input.Position
                break
            end
        end

        local mag = delta.Magnitude
        if mag < thumbstick_deadzone then
            delta = Vector2.zero
        else
            local scaled = (mag - thumbstick_deadzone) / (1 - thumbstick_deadzone)
            delta = delta.Unit * scaled
        end

        if delta.Magnitude > 0 then
            last_input_type = "Gamepad"
        end

        if last_input_type == "Gamepad" and delta.Magnitude > 0 then
            self.camera_angles += Vector2.new(
                delta.Y * gamepad_sensitivity,
                -delta.X * gamepad_sensitivity
            ) * dt * 60

            self.camera_angles = Vector2.new(
                math.clamp(self.camera_angles.X, -80, 80),
                self.camera_angles.Y
            )
        end
    end)

    self.controlling = true

    self.camera = workspace.CurrentCamera
    self.runtime = runService.Heartbeat:Connect(function(deltaTime)
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    if part:HasTag('FPV_Visible') then continue end

                    part.LocalTransparencyModifier = 1
                    part.Transparency = 1
                end
            end
        end

        if not self.controlling then return end

        --> Force FPV
        -- player.CameraMaxZoomDistance = 0
        -- player.CameraMinZoomDistance = 0
        -- player.CameraMode = Enum.CameraMode.LockFirstPerson
        self.camera.CameraType = Enum.CameraType.Scriptable

        userInputs.MouseIconEnabled = false
        userInputs.MouseBehavior = Enum.MouseBehavior.LockCenter

        --> Calculate bobbing
        if not character then fetchCharacter(); return end

        local is_sprinting = movement_cache:getValue('is_sprinting')
        local bob_ampl = is_sprinting and s_bob_ampl or w_bob_ampl
        local tilt_ampl = is_sprinting and s_tilt_ampl or w_tilt_ampl
        local horiz_sway = is_sprinting and s_horiz_sway or w_horiz_sway
        
        local is_moving = humanoid and humanoid.MoveDirection.Magnitude > 0.1
        local move_speed = humanoid and humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed or 0
        
        -- Initialize bob variables
        self.bob_time = self.bob_time or 0
        self.bob_tilt = self.bob_tilt or 0 
        self.bob_offset = self.bob_offset or Vector3.zero
        
        local bob_offset, cam_tilt
        
        if not is_moving then
            self.bob_offset = self.bob_offset:Lerp(Vector3.zero, 8 * deltaTime)
            self.bob_tilt = self.bob_tilt + (0 - self.bob_tilt) * 8 * deltaTime
            
            bob_offset = self.bob_offset
            cam_tilt = self.bob_tilt
        else
            self.bob_time = self.bob_time + deltaTime * bob_freq * math.min(move_speed / 16, 1)

            local vert_bob = math.sin(self.bob_time * 2) * bob_ampl * 0.1
            local horiz_bob = math.sin(self.bob_time) * horiz_sway * 0.05
            local look_bob = math.cos(self.bob_time * 1.5) * bob_ampl * 0.02
            cam_tilt = math.sin(self.bob_time * 1.3) * tilt_ampl

            if is_sprinting then
                local chaos = math.sin(self.bob_time * 3.7) * 0.5 + math.cos(self.bob_time * 2.8) * 0.3  -- Fixed variable
                horiz_bob = horiz_bob + chaos * 0.03
                cam_tilt = cam_tilt + chaos * 1.5
                vert_bob = vert_bob + math.abs(chaos) * 0.02
            end

            bob_offset = Vector3.new(horiz_bob, vert_bob, look_bob)
            self.bob_offset = bob_offset
            self.bob_tilt = cam_tilt
        end

        --> Update camera
        local head_cf = head.CFrame
        local base_pos = head_cf.Position + Vector3.new(0, 0.5, 0)
        
        local pitch_cf = CFrame.Angles(math.rad(self.camera_angles.X), 0, 0)
        local yaw_cf = CFrame.Angles(0, math.rad(self.camera_angles.Y), 0)
        local look_cf = yaw_cf*pitch_cf

        local cam_look, cam_right, cam_up = 
            look_cf.LookVector, look_cf.RightVector, look_cf.UpVector

        local final_pos = base_pos +
            cam_right * bob_offset.X +
            cam_up * bob_offset.Y +
            cam_look * bob_offset.Z
            
        local base_cf = CFrame.lookAt(final_pos, final_pos + cam_look)

        if math.abs(cam_tilt) > 0.01 then
            local tilt_rotation = CFrame.fromAxisAngle(base_cf.LookVector, math.rad(cam_tilt))
            base_cf = base_cf * tilt_rotation
        end
        
        self.camera.CFrame = base_cf + self.camera_offset
    end)

    return self
end

function camera:setControl(can_control: boolean)
    self.controlling = can_control
end

return camera