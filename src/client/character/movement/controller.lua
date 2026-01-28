--[[

    Movement Controller Module
    
    Griffin Dalby
    2025.09.16

    This module contains logic for movement controls.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local starterPlayer = game:GetService('StarterPlayer')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local movement_cache = cache.findCache('movement')
local env_cache = cache.findCache('env')

--]] Settings
local base_speed   = starterPlayer.CharacterWalkSpeed
local sprint_speed = base_speed + 6
local crouch_speed = base_speed - 7

local base_fov   = workspace.CurrentCamera.FieldOfView
local sprint_fov = base_fov + 20
local crouch_fov = base_fov - 10

local acceleration = .1

local crouch_noclip = {
    workspace.environment.hiding_desks
}

--]] Constants
local player = players.LocalPlayer
local character = player.Character
local root_part = character:WaitForChild('HumanoidRootPart') :: Part

local camera = workspace.CurrentCamera

--]] Variables
--]] Functions
local function lerp(a: number, b: number, t: number)
    return a + (b - a) * t
end

local function SetNoclip(noclip_status: boolean)
    for _, model_folder: Folder in pairs(crouch_noclip) do

        for _, model: Instance in pairs(model_folder:GetChildren()) do
            if model:IsA("Model") then

                for _, part: Instance in pairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        print(`Noclip {part:GetFullName()}: {noclip_status}`)
                        part.CollisionGroup = if noclip_status then "CrouchNoclip" else "Default"
                        part.CanCollide = not noclip_status
                    end
                end

            end
        end

    end
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

    stand_queued: boolean,

    character: Model,
    humanoid: Humanoid,

    speed: {number|number},
    fov: {number|number},
    cam_y_off: {number},

    speed_modifiers: {[string]: number}, --> [id]: multiplier
    stand_params: RaycastParams,

    logic: RBXScriptConnection
}
export type MovementController = typeof(setmetatable({} :: self, controller))

function controller.new(env: { camera: { camera_offset: Vector3 } }) : MovementController
    local self = setmetatable({} :: self, controller)

    --> Initalize
    self.can_sprint = true
    self.can_crouch = true
    self.can_jump = true

    self.is_sprinting = false
    self.is_crouched = false
    self.is_jumping = false

    self.stand_queued = false

    movement_cache:setValue('is_sprinting', false)
    movement_cache:setValue('is_crouched', false)

    self.speed = {base_speed, base_speed}
    self.fov = {base_fov, base_fov}
    self.cam_y_off = {0, 0}

    self.speed_modifiers = {}

    self.stand_params = RaycastParams.new()
    self.stand_params.FilterDescendantsInstances = { character }
    self.stand_params.FilterType = Enum.RaycastFilterType.Exclude

    --> Index Player
    local player = players.LocalPlayer
    self.character = player.Character
    self.humanoid = self.character:FindFirstChildOfClass('Humanoid')

    --> Runtime
    local logic_cache: {
        stand_queue_time: number?
    } = {}
    self.logic = runService.Heartbeat:Connect(function(dt)
        if self.stand_queued then
            local sqt = logic_cache.stand_queue_time or 0
            sqt += dt

            if sqt>=45/60 then
                local cast = workspace:Raycast(root_part.Position, root_part.CFrame.UpVector*2.6, self.stand_params)
                if cast then
                    return
                end

                --> Stand up
                self.is_crouched = false
                movement_cache:setValue('is_crouched', false)
                SetNoclip(false)

            end
        end

        --> Crouching
        self.can_sprint = (not self.is_crouched) and not self.is_hiding
        self.can_jump = (not self.is_crouched) and not self.is_hiding

        self.cam_y_off[2] = self.is_crouched and -2.5 or 0
        self.cam_y_off[1] = lerp(self.cam_y_off[1], self.cam_y_off[2], .25)

        env.camera.camera_offset = Vector3.new(0, self.cam_y_off[1], 0)

        if not self.is_hiding then
            --> Move Speed
            if self.is_sprinting then --> Only sprint when moving
                self.can_sprint = self.humanoid.MoveDirection.Magnitude > .1
            end

            self.speed[2] =
                self.is_crouched and crouch_speed or ((self.is_sprinting and self.can_sprint) and sprint_speed or base_speed)
            self.speed[1] = lerp(self.speed[1], self.speed[2], acceleration)

            self.humanoid.WalkSpeed = self.speed[1]
        end

        --> FOV
        self.fov[2] =
            self.is_crouched and crouch_fov or ((self.is_sprinting and self.can_sprint) and sprint_fov or base_fov)
        self.fov[1] = lerp(self.fov[1], self.fov[2], acceleration)

        workspace.CurrentCamera.FieldOfView = self.fov[1]
    end)

    return self
end

function controller:setCrouch(is_crouched: boolean)
    if not self.can_crouch then return end

    --> Raycast Above
    if not is_crouched then
        local cast = workspace:Raycast(root_part.Position, root_part.CFrame.UpVector*2.6, self.stand_params)
        if cast then
            print("Prevent stand due to cast hit")
            self.stand_queued = not is_crouched
            return
        end
    end

    --> Set Crouch Status
    self.is_crouched = is_crouched
    movement_cache:setValue('is_crouched', is_crouched)

    --> Set Noclip
    SetNoclip(is_crouched)
end

function controller:setSprint(is_sprinting: boolean)
    if not self.can_sprint then return end
    self.is_sprinting = is_sprinting
    movement_cache:setValue('is_sprinting', is_sprinting)
end

function controller:setHiding(is_hiding: boolean, hide_att: Attachment)
    self.is_hiding = is_hiding

    self:setSprint(false)
    self:setCrouch(false)
    self.is_jumping = false

    if is_hiding then
        camera.CameraType = Enum.CameraType.Custom
        local base = hide_att.WorldCFrame.Position+Vector3.new(0,2,0)
        local camera_c = env_cache:getValue('camera')

        local did_x_zero = false
        runService:BindToRenderStep('hide_camera', Enum.RenderPriority.Camera.Value, function()
            local rX, rY, rZ = camera.CFrame:ToOrientation()
            if did_x_zero==false then
                rX=0; did_x_zero=true end

            local locker_f = hide_att.WorldCFrame.LookVector
            local locker_y_rot = math.atan2(-locker_f.X, -locker_f.Z)

            local rel_y = rY-locker_y_rot
            if rel_y > math.pi then
                rel_y=rel_y-2*math.pi
            elseif rel_y < -math.pi then
                rel_y=rel_y+2*math.pi
            end

            local lim_x = math.clamp(math.deg(rX), -30, 30)
            local lim_y = math.clamp(math.deg(rel_y), -45, 45)
            local final_y = locker_y_rot+math.rad(lim_y)
            camera.CFrame = CFrame.new(base+camera_c.camera_offset)*CFrame.fromOrientation(math.rad(lim_x), final_y, rZ)
        end)
    else
        runService:UnbindFromRenderStep('hide_camera')
    end
end

return controller