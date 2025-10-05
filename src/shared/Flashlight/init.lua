--[[

    Flashlight Logic

    Griffin Dalby
    2025.09.17

    This module will provide flashlight control logic.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local soundService = game:GetService('SoundService')
local userInputs = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache
local cdn = sawdust.core.cdn

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Cache
local movement_cache = cache.findCache('movement')

--> CDN
local sfx_cdn = cdn.getProvider('sfx')

--]] Modules
--]] Settings
local drain_multi = .25 --> How fast power drains
local power_update_time = 4 --> Duration between each update from server-client

local button_sfx = {
    [true]  = sfx_cdn:getAsset('flashlight_button_pressed'),
    [false] = sfx_cdn:getAsset('flashlight_button_depress')
} :: {[string]: Sound}

--]] Constants
local is_client = runService:IsClient()
local camera = workspace.CurrentCamera

--]] Variables
--]] Functions
--]] Flashlight
local flashlight = {}
flashlight.__index = flashlight

export type self = {
    player: Player,
    toggled: boolean,
    power: number,

    light_behavior: RBXScriptConnection,

    --> Client
    light_part: Part,
    visual_runtime: RBXScriptConnection,
}
export type Flashlight = typeof(setmetatable({} :: self, flashlight))

function flashlight.new(player: Player?) : Flashlight
    local self = setmetatable({} :: self, flashlight)

    self.player = is_client and players.LocalPlayer or player
    local env: {} = is_client and player or nil

    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local root_part = character.PrimaryPart

    self.toggled = false
    self.power = 100
    
    local time_since_update = 0
    self.light_behavior = runService.Heartbeat:Connect(function(dT)
        if self.toggled then
            self.power -= drain_multi*dT
            
            if not is_client then
                time_since_update+=dT
                if time_since_update>power_update_time then
                    time_since_update = 0
                    mechanics.flashlight:with()
                        :intent('update_power')
                        :data(self.power)
                        :broadcastTo{self.player}
                        :fire()
                end
            end
        end
    end)

    if is_client then
        self.light_part = script.LightPart:Clone()
        self.light_part.Parent = workspace.CurrentCamera

        local mouse_delta = Vector2.zero
        local raw_mouse_delta = Vector2.zero

        self.mouse_connection = userInputs.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                raw_mouse_delta = Vector2.new(input.Delta.X, input.Delta.Y)
            end
        end)

        self.visual_runtime = runService.Heartbeat:Connect(function(dT)
            if self.light_part and root_part then
                self.light_part.DirectLight.Enabled = self.toggled
                self.light_part.WideLight.Enabled = self.toggled
                
                if self.toggled then
                    mouse_delta = mouse_delta:Lerp(
                        raw_mouse_delta*.035,
                        12.5*dT )

                    local cam_pitch = math.deg(math.asin(-camera.CFrame.LookVector.Y))
                    local max_pitch = 75
                    local pitch_fade_zone = 45

                    local fade_fac = 1
                    if math.abs(cam_pitch) > (max_pitch - pitch_fade_zone) then
                        fade_fac = math.max(0, (max_pitch - math.abs(cam_pitch)) / pitch_fade_zone) end

                    local lead_strength = movement_cache:getValue('is_crouched') and 3 or 2.65
                    local lead_vector = Vector3.new(
                        mouse_delta.X*lead_strength*fade_fac,
                        -mouse_delta.Y*(lead_strength*.6)*fade_fac,
                        0
                    )

                    local base_dir = camera.CFrame.LookVector
                    local lead_dir = (base_dir + camera.CFrame:VectorToWorldSpace(lead_vector)).Unit
                    
                    local flashlight_offset = Vector3.new(.4, -.2, 0)

                    local target_cf  = CFrame.lookAt(
                        camera.CFrame.Position + camera.CFrame:VectorToWorldSpace(flashlight_offset),
                        camera.CFrame.Position + lead_dir*5
                    )

                    local movement_intensity = mouse_delta.Magnitude
                    local lerp_speed = math.clamp(6+movement_intensity*8, 4, 18)

                    local bob_off = env.camera.bob_offset or Vector3.zero
                    local is_sprinting = env.movement.is_sprinting or false
                    local bob_vec = camera.CFrame:VectorToWorldSpace(Vector3.new(
                        bob_off.X*(is_sprinting and 5 or 15),
                        bob_off.Y*(is_sprinting and 2.5 or 15),
                        bob_off.Z*0
                    ))
                    self.bob_smooth = self.bob_smooth and self.bob_smooth:Lerp(bob_vec, 10*dT) or bob_vec

                    self.light_part.CFrame = self.light_part.CFrame:Lerp(target_cf, lerp_speed*dT)
                    self.light_part.CFrame += self.bob_smooth
                    raw_mouse_delta = raw_mouse_delta*.9
                else
                    -- When flashlight is off, position it near your hand
                    local hand_offset = Vector3.new(0.3, -0.4, 0.1)
                    self.light_part.CFrame = self.light_part.CFrame:Lerp(
                        camera.CFrame + camera.CFrame:VectorToWorldSpace(hand_offset), 
                        4 * dT
                    )
                end
            else
                if not root_part then
                    character = self.player.Character or nil
                    if not character then return end

                    root_part = character.PrimaryPart
                end
            end
        end)
    end

    return self
end

function flashlight:toggle(button_pressed: boolean) : boolean
    if is_client then
        --> Authenticate
        if self.toggled and button_pressed then
            self.toggled = false

            return true
        elseif not self.toggled and not button_pressed then
            self.toggled = true
        end
    end
end

return flashlight