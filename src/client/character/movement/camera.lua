--[[

    Camera Controller Module

    Griffin Dalby
    2025.09.16

    This provides the required runtimes for the Camera systems & behavior.

--]]

--]] Services
local userInputs = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Funtions
--]] Module
local camera = {}
camera.__index = camera

type self = {
    camera: Camera,
    runtime: RBXScriptConnection,
}
export type CameraController = typeof(setmetatable({} :: self, camera))

function camera.init() : CameraController
    local self = setmetatable({} :: self, camera)

    local player = players.LocalPlayer

    self.camera = workspace.CurrentCamera
    self.runtime = runService.Heartbeat:Connect(function(deltaTime)
        --> Force FPV
        player.CameraMaxZoomDistance = 0
        player.CameraMinZoomDistance = 0
        player.CameraMode = Enum.CameraMode.LockFirstPerson

        userInputs.MouseIconEnabled = false
    end)

    return self
end

return camera