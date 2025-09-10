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
    self.root_ui = builder_data.root_ui:Clone()

    self.env = {}
    self.env.root = self.root_ui

    local function wrap_f(handler)
        return function(...)
            handler(self.env, ...)
        end
    end

    self.update = {
        object  = wrap_f(builder_data._set_object),
        action  = wrap_f(builder_data._set_action),
        binding = wrap_f(builder_data._set_binding),
        
        set_cooldown  = builder_data._no_cooldown
            and nil or wrap_f(builder_data._set_cooldown),
        cooldown_tick = builder_data._no_cooldown
            and nil or wrap_f(builder_data._update_cooldown),
    }

    return self
end

function promptUi:render(target: BasePart, information: {})
    assert(self.__runtime==nil, `PromptUI visualization runtime already in use!`)

    self.__runtime = runService.Heartbeat:Connect(function()
        self.root_ui.Parent = prompt_container
        
        local vector, onScreen = camera:WorldToViewportPoint(target.Position)
        self.root_ui.Visible = onScreen
        if not onScreen then return end

        self.root_ui.Position = UDim2.new(0, vector.X, 0, vector.Y)
    end)
end
function promptUi:unrender()
    if self.__runtime then
        self.__runtime:Disconnect()
        self.__runtime = nil
    end

    self.root_ui.Parent = script
    self.root_ui.Visible = false
end

function promptUi:set_object(object_name: string)
    self.update.object(object_name) end
function promptUi:set_action(action: string)
    self.update.action(action) end
function promptUi:set_binding(key: Enum.KeyCode, type: Enum.UserInputType)
    self.update.binding(key, type) end

function promptUi:set_cooldown(on_cooldown: boolean)
    self.update.set_cooldown(on_cooldown) end
function promptUi:cooldown_tick(time_remaining: number)
    self.update.cooldown_tick(time_remaining) end

return promptUi