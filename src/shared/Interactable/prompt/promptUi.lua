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
local prompt_scale_range = {.75, 1.5}

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

--[[ promptUi.new(builder_data: PromptUiBuilder) : PromptUi
    This constructs a PromptUi with cohesive update triggers from a
    provided PromptUiBuilder. ]]
function promptUi.new(builder_data: types.PromptUiBuilder) : types.PromptUi
    local self = setmetatable({} :: types._self_prompt_ui, promptUi)

    --]] Construct Data
    self.uuid = https:GenerateGUID()
    self.root_ui = builder_data.root_ui:Clone()
    self.orig_scale = self.root_ui.Size
    self.max_range = 12.5

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

        pre_trigger = wrap_f(builder_data._pre_trigger),
        triggered = wrap_f(builder_data._triggered)
    }
    self.targets = {}

    return self
end

--[[ promptUi:render(target: BasePart)
    Starts the render runtime if there isn't one already, and no matter
    what add the target to the internal targets list. ]]
function promptUi:render(target: BasePart)
    local root_target = target:IsA('Model') and target.PrimaryPart or target
    local target_i = table.find(self.targets, root_target)
    if not target_i then
        table.insert(self.targets, root_target) end

    if self.__runtime then return end

    local l_target_upd = 1
    local ui_descs = self.root_ui:GetDescendants() --> Cache ui Descendants

    self.__runtime = runService.Heartbeat:Connect(function(dT)
        --> Distance
        local camera_pos = workspace.CurrentCamera.CFrame.Position+workspace.CurrentCamera.CFrame.LookVector
        if l_target_upd > .33 then
            local max = {math.huge, nil}
            for _, target in pairs(self.targets) do
                local dist = (camera_pos-target.Position).Magnitude
                if dist < max[1] then
                    max = {dist, target}
                end
            end
            if not max[1] then
                warn(`All targets exhausted, unrendering promptUi!`)
                self:unrender()
                return end
            self.target = max[2]
        end

        --> Render UI
        local ui_dist = (camera_pos-self.target.Position).Magnitude
        local min_ui_dist = 2

        local t = math.clamp((ui_dist-min_ui_dist)/(self.max_range-min_ui_dist), 0, 1)
        local scale_multi = prompt_scale_range[2]*(1-t)+prompt_scale_range[1]*t
        self.root_ui.Size = UDim2.new( 
            self.orig_scale.X.Scale*scale_multi, self.orig_scale.X.Offset*scale_multi,
            self.orig_scale.Y.Scale*scale_multi, self.orig_scale.Y.Offset*scale_multi )

        self.root_ui.Parent = prompt_container
        
        local screen_center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local vector, onScreen = camera:WorldToViewportPoint(self.target.Position)
        local targetPos = Vector2.new(vector.X, vector.Z)
        local distance = (targetPos-screen_center).Magnitude

        self.root_ui.Visible = onScreen
        if not onScreen then return end

        self.root_ui.Position = UDim2.new(0, vector.X, 0, vector.Y)
        
        --> Calc ZIdx
        local max_dist = math.max(camera.ViewportSize.X, camera.ViewportSize.Y)/2
        local normalized = math.clamp(1-(distance/max_dist), 0, 1)
        local base_z_idx = math.floor(normalized*100)
        for _, child: GuiObject in pairs(ui_descs) do
            if not child:IsA('GuiObject') then continue end
            child.ZIndex = base_z_idx+child.ZIndex
        end

        self.root_ui.ZIndex = base_z_idx
        self.zindex = base_z_idx
    end)
end

--[[ promptUi:unrender(target: BasePart)
    Removes the "target" arument from the internal targets table, and if
    no targets remain the render runtime will be disconnected and everything
    cleaned up. ]]
function promptUi:unrender(target: BasePart)
    local root_target = target:IsA('Model') and target.PrimaryPart or target
    local target_i = table.find(self.targets, root_target)
    if target_i then
        table.remove(self.targets, target_i) end
    if #self.targets==0 then
        if self.__runtime then
            self.__runtime:Disconnect()
            self.__runtime = nil
        end

        self.root_ui.Parent = script
        self.root_ui.Visible = false

        self.zindex = nil
        self.target = nil
    end
    
end

--]] Sets the maximum range you can interact with this prompt with.
function promptUi:set_max_range(range: number)
    assert(range, `Attempt to :set_max_range() to nil value!`)
    assert(type(range) == 'number', 
        `Attempt to :set_max_range() to a non-number!`)

    self.max_range = range end

--]] Calls the internal update function for set_object (update.object())
function promptUi:set_object(object_name: string)
    self.update.object(object_name) end

--]] Calls the internal update function for set_action (update.action())
function promptUi:set_action(action: string)
    self.update.action(action) end

--]] Calls the internal update function for set_targeted (update.targeted())
function promptUi:set_targeted(targeted: boolean)
    self.update.targeted(targeted) end

--]] Calls the internal update function for set_binding (update.binding())
function promptUi:set_binding(key: Enum.KeyCode, type: Enum.UserInputType)
    self.update.binding(key, type) end



--]] Calls the internal update function for set_cooldown (update.set_cooldown())
function promptUi:set_cooldown(on_cooldown: boolean)
    self.update.set_cooldown(on_cooldown) end

--]] Calls the internal update connection function for cooldown_tick (update.cooldown_tick())
function promptUi:cooldown_tick(time_remaining: number)
    self.update.cooldown_tick(time_remaining) end

return promptUi