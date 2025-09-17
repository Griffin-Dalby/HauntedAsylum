--[[

    Flashlight Logic

    Griffin Dalby
    2025.09.17

    This module will provide flashlight control logic.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--> Networking
local mechanics = networking.getChannel('mechanics')

--]] Modules
--]] Settings
local drain_multi = .25

local power_update_delta = 4

--]] Constants
local is_client = runService:IsClient()

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
        self.light_part = Instance.new('Part')
        self.light_part.Size = Vector3.one
        self.light_part.Transparency = 1
        self.light_part.Anchored = true
        self.light_part.CanCollide = false

        self.light = Instance.new('SpotLight')
        self.light.Parent = self.light_part

        self.visual_runtime = runService.Heartbeat:Connect(function()
            self.light_part.CFrame = workspace.CurrentCamera.CFrame
            self.light.Enabled = self.toggled
        end)
    end

    return self
end

return flashlight