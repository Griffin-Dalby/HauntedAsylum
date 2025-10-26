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
local soundService = game:GetService('SoundService')
local runService = game:GetService('RunService')

--]] Modules
local camera = require(script:WaitForChild('camera'))
local controller = require(script:WaitForChild('controller'))

local flashlight = require(replicatedStorage.Shared.Flashlight)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache
local cdn = sawdust.core.cdn

--> CDN
local sfx_cdn = cdn.getProvider('sfx')

--> Cache
local c_env = cache.findCache('env')

--]] Settings
local keybinds = {
    crouch = {Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonR3},
    sprint = {Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3},
    toggle_flashlight = { Enum.KeyCode.F, Enum.KeyCode.ButtonY }
}

local button_sfx = {
    [true]  = sfx_cdn:getAsset('flashlight_button_pressed'),
    [false] = sfx_cdn:getAsset('flashlight_button_depress')
} :: {[string]: Sound}

--]] Constants
local rng = Random.new()

--]] Variables
--]] Functions
--]] Script
local env = {}

env.camera = camera.init(env)
env.movement = controller.new(env)
env.flashlight = flashlight.new(env)

c_env:setValue('camera', env.camera)
c_env:setValue('movement', env.movement)
c_env:setValue('flashlight', env.flashlight)

--]] Crouch Behavior
contextActions:BindAction('crouch', function(_, inputState)
    local is_crouched = inputState == Enum.UserInputState.Begin
    env.movement:setCrouch(is_crouched)
end, false, unpack(keybinds.crouch))

contextActions:BindAction('sprint', function(_, inputState)
    local is_sprinting = inputState == Enum.UserInputState.Begin
    env.movement:setSprint(is_sprinting)
end, false, unpack(keybinds.sprint))

--]] Flashlight Behavior
local did_toggle = false
contextActions:BindAction('toggle_flashlight', function(_, state)
    if state~=Enum.UserInputState.Begin and state~=Enum.UserInputState.End then return end

    local button_pressed = (state == Enum.UserInputState.Begin)
    if state == Enum.UserInputState.Begin or state == Enum.UserInputState.End then
        button_sfx[button_pressed].PlaybackSpeed = rng:NextNumber(.8, 1.2)
        soundService:PlayLocalSound(button_sfx[button_pressed])
    end
    if not did_toggle then
        did_toggle = env.flashlight:toggle(button_pressed)
    else
        did_toggle = false
    end
end, false, unpack(keybinds.toggle_flashlight))