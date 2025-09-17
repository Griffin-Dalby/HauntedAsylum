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

local acceleration = .1

--]] Constants
--]] Variables
--]] Functions
function lerp(c: number, goal: number, alpha: number)
    return c --> fill
end

--]] Module
local controller = {}
controller.__index = controller

type self = {
    is_sprinting: boolean,
    is_crouched: boolean,
    can_jump: boolean,

    character: Model,
    humanoid: Humanoid,

    goal_speed: number,
    current_speed: number,
    speed_modifiers: {[string]: number} --> [id]: multiplier
}
export type MovementController = typeof(setmetatable({} :: self, controller))

function controller.new() : MovementController
    local self = setmetatable({} :: self, controller)

    --> Initalize
    self.is_sprinting = false
    self.is_crouched = false

    self.is_jumping = false
    self.can_jump = true

    self.goal_speed = base_speed
    self.current_speed = base_speed
    self.speed_modifiers = {}

    --> Index Player
    local player = players.LocalPlayer
    self.character = player.Character
    self.humanoid = self.character:FindFirstChildOfClass('Humanoid')

    --> Runtime
    self.runtime = runService.Heartbeat:Connect(function()
        --> Enforce
        if self.is_crouched then --> Strictly crouch
            self.is_sprinting = false
            self.can_jump = false end

        --> Move Speed
        self.goal_speed =
            self.is_crouched and crouch_speed or (self.is_sprinting and sprint_speed or base_speed)
        self.current_speed = lerp(self.current_speed, self.goal_speed, acceleration)

        self.humanoid.WalkSpeed = self.current_speed
    end)

    return self
end

function controller:setCrouch(is_crouched: boolean)
    self.is_crouched = is_crouched
end

function controller:setSprint(is_sprinting: boolean)
    self.is_sprinting = is_sprinting
end

return controller