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
local maid = sawdust.util.maid
local cdn = sawdust.core.cdn

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Cache
local movement_cache = cache.findCache('movement')

--> CDN
local sfx_cdn = cdn.getProvider('sfx')

--]] Modules
--]] Settings
local __debug = false

local drain_multi = .85 --> How fast power drains
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
function lerp(a,b, t)
    return a+(b-a)*t
end

function flashlightFalloff(value_range: {}, alpha_range: {}, current)
    return 
        (value_range[2]-value_range[1])
        *math.pow((current-alpha_range[1])/(alpha_range[1]-alpha_range[2]), 4)+value_range[1]
end

function getFlicker(intensity)
    return 1 - intensity * (0.5 + 0.5 * math.noise(os.clock() * 8))
end

local __cutout_timer = 0
function getFlickerMulti(power)
    local flicker_multi = 1
    if power <= 10 and power >= 0 then
        if __cutout_timer > 0 then
            flicker_multi = 0
            __cutout_timer -= 1
        elseif math.random() < 0.04 then
            __cutout_timer = math.random(2, 6)
            flicker_multi = 0
        else
            flicker_multi = getFlicker(.5)
        end
    elseif power <= 16 and power > 10 then
        flicker_multi = getFlicker(.4)*(math.random()<.04 and 1.5 or 1)
    elseif power <= 22 and power > 16 then
        flicker_multi = getFlicker(.275)
    elseif power <= 30 and power > 22 then
        flicker_multi = getFlicker(.15)
    end

    return flicker_multi
end

--]] Flashlight
local flashlight = {}
flashlight.__index = flashlight

export type self = {
    __maid: sawdust.SawdustMaid,

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
    self.__maid = maid.new(self)

    self.player = is_client and players.LocalPlayer or player
    local env: {} = is_client and player or nil

    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local root_part = character.PrimaryPart

    self.toggled = false
    self.power = 100
    
    local time_since_update = 0

    self.light_behavior = self.__maid:add(runService.Heartbeat:Connect(function(dT)
        if self.toggled then
            if self.power <= 0 then
                self.power = 0
                self.toggled = false
            end
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
            else
                --> UI
                local flash_bar: Frame = self.player.PlayerGui.UI.Stats.Flashlight
                if flash_bar:GetAttribute('transparency') then
                    flash_bar:SetAttribute('transparency', nil) end
                flash_bar.BackgroundTransparency = .25
                flash_bar.Bar.BackgroundTransparency = 0
                flash_bar.Bar.Size =
                    UDim2.new(self.power/100, 0, 1, 0)

                --> Charge's affect on the light
                local charge_range = {100, 0}

                local direct_brightness = {.42, 0}
                local wide_brightness = {.05, 0}

                local direct_fBright = flashlightFalloff(direct_brightness, charge_range, self.power)
                local wide_fBright = flashlightFalloff(wide_brightness, charge_range, self.power)

                local flicker_multi = getFlickerMulti(self.power)
                self.light_part.DirectLight.Brightness, self.light_part.WideLight.Brightness = 
                    direct_fBright*flicker_multi, wide_fBright*flicker_multi/2
            end
        else
            if is_client then
                local flash_bar: Frame = self.player.PlayerGui.UI.Stats.Flashlight
                if flash_bar:GetAttribute('transparency') then
                    return end
                local this_id = tick()
                flash_bar:SetAttribute('transparency', this_id)
                
                local alpha = 0

                local conn; conn = runService.Heartbeat:Connect(function()
                    local transp_attb = flash_bar:GetAttribute('transparency')
                    if transp_attb~=this_id then
                        conn:Disconnect()
                        conn = nil

                        flash_bar.BackgroundTransparency = .75
                        flash_bar.Bar.BackgroundTransparency = .75
                        return
                    end

                    alpha+=dT*7.5
                    flash_bar.BackgroundTransparency = lerp(.25, .75, alpha)
                    flash_bar.Bar.BackgroundTransparency = lerp(0, .75, alpha)
                    
                    if alpha>=1 then
                        conn:Disconnect()
                        conn = nil
                        flash_bar.BackgroundTransparency = .75
                        flash_bar.Bar.BackgroundTransparency = .75
                    end
                end)
            end
        end
    end))

    if is_client then
        local s = mechanics.flashlight:with()
            :intent('init')
            :timeout(5)
            :invoke():wait()
        assert(s, `Server abstains from initalizing our flashlight!`)

        self.light_part = self.__maid:add(script.LightPart:Clone())
        self.light_part.Parent = workspace.CurrentCamera

        local last_input_type = "KBM"
        local raw_mouse_delta = Vector2.zero
        local mouse_delta = Vector2.zero

        local prev_stick = Vector2.zero

        self.mouse_connection = self.__maid:add(userInputs.InputChanged:Connect(function(input)
            if not self.player.Character then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                raw_mouse_delta = Vector2.new(input.Delta.X, input.Delta.Y)
                last_input_type = "KBM"

            elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
                if input.KeyCode == Enum.KeyCode.Thumbstick2 then
                    local stick = Vector2.new(input.Position.X, input.Position.Y)
                    local delta = stick - prev_stick
                    prev_stick = stick

                    raw_mouse_delta = delta * 50
                    last_input_type = "Gamepad"
                end
            end
        end))

        self.visual_runtime = self.__maid:add(runService.Heartbeat:Connect(function(dT)
            if not self.player.Character then return end
            if self.light_part and root_part then
                self.light_part.DirectLight.Enabled = self.toggled
                self.light_part.WideLight.Enabled = self.toggled
                
                if self.toggled then
                    mouse_delta = mouse_delta:Lerp(
                        raw_mouse_delta*.035,
                        12.5*dT )

                    local cam_pitch = math.deg(math.asin(-camera.CFrame.LookVector.Y))
                    local max_pitch, pitch_fade_zone = 75, 45

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
        end))
    
        self.update_power = self.__maid:add(
            mechanics.flashlight:route():on('update_power', function(req, res)
                if __debug then print(`[{script.Name}] Synced power to server-time! (diff: {self.power-req.data[1]})`) end
                self.power = req.data[1]
        end))
    end

    return self
end

function flashlight:toggle(button_pressed: boolean) : boolean
    if is_client then
        --> Authenticate
        local updated = false
        if self.toggled and button_pressed then
            self.toggled = false
            updated = true
        elseif not self.toggled and not button_pressed then
            self.toggled = true
            updated = true
        end

        mechanics.flashlight:with()
            :intent('toggle')
            :data(self.toggled)
            :invoke():catch(function(data)
                if __debug then print(`[{script.Name}] Server synced toggle status to {data[1]}`) end
                self.toggled = data[1]
            end)
        return updated and self.toggled==false
    else
        --> Sanitize
        local target_state = button_pressed
        if target_state==self.toggled then return false end

        --> Finalize
        self.toggled = target_state
        return true
    end
end

function flashlight:discard()
    self.__maid:clean()
end

return flashlight