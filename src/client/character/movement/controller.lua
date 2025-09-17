--[[

    Movement Controller Module
    
    Griffin Dalby
    2025.09.16

    This module contains logic for movement controls.

--]]

--]] Services
local starterPlayer = game:GetService('StarterPlayer')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Settings
local base_speed   = starterPlayer.CharacterWalkSpeed
local sprint_speed = base_speed + 6
local crouch_speed = base_speed - 7

local base_fov   = workspace.CurrentCamera.FieldOfView
local sprint_fov = base_fov + 20
local crouch_fov = base_fov - 10

local acceleration = .1

--]] Constants
--]] Variables
--]] Functions
function lerp(a: number, b: number, t: number)
    return a + (b - a) * t
end

--]] Module
local controller = {}
controller.__index = controller

type self = {
    can_sprint: boolean,
    can_crouch: boolean,
    can_jump: boolean,

    is_sprinting: boolean,
    is_crouched: boolean,
    is_jumping: boolean,

    character: Model,
    humanoid: Humanoid,

    speed: {number|number},
    fov: {number|number},
    speed_modifiers: {[string]: number}, --> [id]: multiplier

    logic: RBXScriptConnection
}
export type MovementController = typeof(setmetatable({} :: self, controller))

function controller.new() : MovementController
    local self = setmetatable({} :: self, controller)

    --> Initalize
    self.can_sprint = true
    self.can_crouch = true
    self.can_jump = true

    self.is_sprinting = false
    self.is_crouched = false
    self.is_jumping = false

    self.speed = {base_speed, base_speed}
    self.fov = {base_fov, base_fov}
    self.cam_y_off = {0, 0}

    self.speed_modifiers = {}

    --> Index Player
    local player = players.LocalPlayer
    self.character = player.Character
    self.humanoid = self.character:FindFirstChildOfClass('Humanoid')

    --> Runtime
    self.logic = runService.Heartbeat:Connect(function()
        --> Crouching
        self.can_sprint = not self.is_crouched
        self.can_jump = not self.is_crouched

        self.cam_y_off[2] = self.is_crouched and -2 or 0
        self.cam_y_off[1] = lerp(self.cam_y_off[1], self.cam_y_off[2], .25)

        self.humanoid.CameraOffset = Vector3.new(0, self.cam_y_off[1], 0)

        --> Move Speed
        if self.is_sprinting then --> Only sprint when moving
            self.can_sprint = self.humanoid.MoveDirection.Magnitude > .1
        end

        self.speed[2] =
            self.is_crouched and crouch_speed or ((self.is_sprinting and self.can_sprint) and sprint_speed or base_speed)
        self.speed[1] = lerp(self.speed[1], self.speed[2], acceleration)

        self.humanoid.WalkSpeed = self.speed[1]

        --> FOV
        self.fov[2] =
            self.is_crouched and crouch_fov or ((self.is_sprinting and self.can_sprint) and sprint_fov or base_fov)
        self.fov[1] = lerp(self.fov[1], self.fov[2], acceleration)

        workspace.CurrentCamera.FieldOfView = self.fov[1]
    end)

    return self
end

function controller:setCrouch(is_crouched: boolean)
    self.is_crouched = is_crouched
end

function controller:setSprint(is_sprinting: boolean)
    if not self.can_sprint then return end
    self.is_sprinting = is_sprinting
end

return controller