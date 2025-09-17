--[[

    Flashlight Logic

    Griffin Dalby
    2025.09.17

    This module will provide flashlight control logic.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local soundService = game:GetService('SoundService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cdn = sawdust.core.cdn

--> Networking
local mechanics = networking.getChannel('mechanics')

--> CDN
local sfx_cdn = cdn.getProvider('sfx')

--]] Modules
--]] Settings
local drain_multi = .25 --> How fast power drains
local power_update_delta = 4 --> Duration between each update from server-client

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

    --> Client
    light_part: Part,
    light: SpotLight,
    visual_runtime: RBXScriptConnection,
}
export type Flashlight = typeof(setmetatable({} :: self, flashlight))

function flashlight.new(player: Player?) : Flashlight
    local self = setmetatable({} :: self, flashlight)

    self.player = is_client and players.LocalPlayer or player
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
                if time_since_update>power_update_delta then
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

        self.light = self.light_part:FindFirstChild('Light') :: SpotLight

        self.visual_runtime = runService.Heartbeat:Connect(function()
            if self.light_part and root_part then
                self.light_part.CFrame = workspace.CurrentCamera.CFrame
                self.light.Enabled = self.toggled

                self.light_part.CFrame = self.light_part.CFrame:Lerp(
                    camera.CFrame - root_part.CFrame.LookVector, .6 )
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