--[[

    PromptUI Object

    Griffin Dalby
    2025.09.08

    This module will provide a PromptUi instance that can be cloned
    and destroyed.

--]]

--]] Services
local runService = game:GetService('RunService')
local players = game:GetService('Players')
local https = game:GetService('HttpService')

--]] Modules
local types = require(script.Parent.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
local is_client = runService:IsClient()

--> Index player
local player = is_client and players.LocalPlayer
local player_ui = is_client and player.PlayerGui

local prompt_container = is_client and player_ui:WaitForChild('__prompts')

local camera = workspace.CurrentCamera

--]] Variables
--]] Functions
--]] Module
local promptUi = {}
promptUi.__index = promptUi

function promptUi.new(builder_data: types.PromptUiBuilder) : types.PromptUi
    local self = setmetatable({} :: types._self_prompt_ui, promptUi)

    --]] Construct Data
    self.uuid = https:GenerateGUID()
    self.root_ui = builder_data.root_ui:Clone()

    self.env = {}
    self.env.root = self.root_ui

    local function wrap_f(handler)
        return function(...)
            handler(self.env, ...)
        end
    end

    self.update = {
        object   = wrap_f(builder_data._set_object),
        action   = wrap_f(builder_data._set_action),
        targeted = wrap_f(builder_data._set_targeted),
        binding  = wrap_f(builder_data._set_binding),
        
        set_cooldown  = if not builder_data._no_cooldown then
            wrap_f(builder_data._set_cooldown) else nil,
        cooldown_tick = if not builder_data._no_cooldown then
            wrap_f(builder_data._update_cooldown) else nil,
    }

    return self
end

function promptUi:render(target: BasePart, information: {})
    assert(self.__runtime==nil, `PromptUI visualization runtime already in use!`)

    self.__runtime = runService.Heartbeat:Connect(function()
        --> Render UI
        self.root_ui.Parent = prompt_container
        
        local screen_center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local vector, onScreen = camera:WorldToViewportPoint(target.Position)
        local targetPos = Vector2.new(vector.X, vector.Z)
        local distance = (targetPos-screen_center).Magnitude

        self.root_ui.Visible = onScreen
        if not onScreen then return end

        self.root_ui.Position = UDim2.new(0, vector.X, 0, vector.Y)
        
        --> Calc ZIdx
        local max_dist = math.max(camera.ViewportSize.X, camera.ViewportSize.Y)/2
        local normalized = math.clamp(1-(distance/max_dist), 0, 1)
        local base_z_idx = math.floor(normalized*100)
        for _, child: GuiObject in pairs(self.root_ui:GetDescendants()) do
            if not child:IsA('GuiObject') then continue end

            child.ZIndex = base_z_idx+child.ZIndex
        end

        self.root_ui.ZIndex = base_z_idx
        self.zindex = base_z_idx
    end)
end
function promptUi:unrender()
    if self.__runtime then
        self.__runtime:Disconnect()
        self.__runtime = nil
    end

    self.root_ui.Parent = script
    self.root_ui.Visible = false

    self.zindex = nil
end

function promptUi:set_object(object_name: string)
    self.update.object(object_name) end
function promptUi:set_action(action: string)
    self.update.action(action) end
function promptUi:set_targeted(targeted: boolean)
    self.update.targeted(targeted) end
function promptUi:set_binding(key: Enum.KeyCode, type: Enum.UserInputType)
    self.update.binding(key, type) end

function promptUi:set_cooldown(on_cooldown: boolean)
    self.update.set_cooldown(on_cooldown) end
function promptUi:cooldown_tick(time_remaining: number)
    self.update.cooldown_tick(time_remaining) end

return promptUi