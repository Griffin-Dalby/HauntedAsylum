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
local sawdust = require(replicatedStorage.Sawdust)
local camera = require(script.camera)
local controller = require(script.controller)

--]] Modules
--]] Settings
local keybinds = {
    crouch = {Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3},
    sprint = {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3}
}

--]] Constants
--]] Variables
--]] Functions
--]] Script
camera.init()
local movement = controller.new()

--]] Crouch Behavior
contextActions:BindAction('crouch', function(_, inputState)
    local is_crouched = inputState == Enum.UserInputState.Begin
    movement:setCrouch(is_crouched)
end, false, unpack(keybinds.crouch))

contextActions:BindAction('sprint', function(_, inputState)
    local is_sprinting = inputState == Enum.UserInputState.Begin
    movement:setSprint(is_sprinting)
end, false, unpack(keybinds.sprint))