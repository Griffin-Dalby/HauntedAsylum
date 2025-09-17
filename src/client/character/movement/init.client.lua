--[[

    Movement Controller

    Griffin Dalby
    2025.09.14

    This script will provide a controller for player movement, and
    camera movements.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local contextActions = game:GetService('ContextActionService')
local runService = game:GetService('RunService')

--]] Sawdust
local sawdust = require(replicatedStorage.Shared.Sawdust)
local camera = require(script.camera)

--]] Modules
--]] Settings
local keybinds = {
    crouch = {Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3}
}

--]] Constants
--]] Variables
--]] Functions
--]] Script
camera.init()

--]] Crouch Behavior
contextActions:BindAction('crouch', function(_, inputState)
    local is_crouched = inputState == Enum.UserInputState.Begin
    
end, unpack(keybinds.crouch))