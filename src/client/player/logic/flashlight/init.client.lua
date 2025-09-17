--[[

    Flashlight Client-Side Logic

    Griffin Dalby
    2025.09.17

    This script will control the client-sided logic for flashlights

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local contextActions = game:GetService('ContextActionService')
local soundService = game:GetService('SoundService')

--]] Modules
local flashlight = require(replicatedStorage.Shared.Flashlight)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cdn = sawdust.core.cdn

--> CDN
local sfx_cdn = cdn.getProvider('sfx')

--]] Settings
local keybinds = {
    toggle_flashlight = { Enum.KeyCode.F, Enum.KeyCode.ButtonY }
}

local button_sfx = {
    [true]  = sfx_cdn:getAsset('flashlight_button_pressed'),
    [false] = sfx_cdn:getAsset('flashlight_button_depress')
} :: {[string]: Sound}

--]] Constants
--]] Variables
--]] Functions
--]] Script
local this_flashlight = flashlight.new()
local did_toggle = false

local rng = Random.new()
contextActions:BindAction('toggle_flashlight', function(_, state)
    local button_pressed = (state == Enum.UserInputState.Begin)
    if state == Enum.UserInputState.Begin or state == Enum.UserInputState.End then
        button_sfx[button_pressed].PlaybackSpeed = rng:NextNumber(.8, 1.2)
        soundService:PlayLocalSound(button_sfx[button_pressed])
    end
    if not did_toggle then
        did_toggle = this_flashlight:toggle(button_pressed)
    else
        did_toggle = false
    end
end, false, unpack(keybinds.toggle_flashlight))