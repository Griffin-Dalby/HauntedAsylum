--[[

    Flashlight Client-Side Logic

    Griffin Dalby
    2025.09.17

    This script will control the client-sided logic for flashlights

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local contextActions = game:GetService('ContextActionService')

--]] Modules
--]] Sawdust
--]] Settings
local keybinds = {
    toggle_flashlight = { Enum.KeyCode.F, Enum.KeyCode.ButtonY }
}

--]] Constants
--]] Variables
--]] Functions
--]] Script
contextActions:BindAction('toggle_flashlight', function(_, state)
    if state ~= Enum.UserInputState.Begin then return end

    
end, false, unpack(keybinds.toggle_flashlight))