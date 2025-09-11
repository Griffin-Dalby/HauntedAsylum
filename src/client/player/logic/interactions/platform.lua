--[[

    Platform Module

    Griffin Dalby
    2025.09.11

    This module will provide a interface to map values to specific platform
    indicators, like bindings on different platforms.

--]]

--]] Services
local userInputService = game:GetService('UserInputService')

--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
--]] Settings
local gamepad_inputs = {
    Enum.KeyCode.ButtonA,
	Enum.KeyCode.ButtonB,
	Enum.KeyCode.ButtonX,
	Enum.KeyCode.ButtonY,

	Enum.KeyCode.ButtonL1,
	Enum.KeyCode.ButtonL2,
	Enum.KeyCode.ButtonL3,

	Enum.KeyCode.ButtonR1,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonR3,

	Enum.KeyCode.ButtonStart,

	Enum.KeyCode.DPadUp,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadRight,

    Enum.KeyCode.Thumbstick1,
    Enum.KeyCode.Thumbstick2
}

local binding_data = {} --> TODO: Fill
--> Make sure to rename the platforms to whats used in this, like ps for playstation.

--]] Constants
--]] Variables
--]] Functions
--]] Module
local platform = {}
platform.__index = platform

--[[ platform.new() : PlatformMap
    Constructor function for a PlatformMap, which will store the state
    and provide logic for updating. ]]
function platform.new() : types.PlatformMap
    local self = setmetatable({} :: types._self_platform, platform)

    --[[ Platforms:
        'desktop'
        'console'
        'mobile'
    --]]
    self.platform = 'desktop'

    --[[ Brands:
        'generic' (unknown / non-console)
        'xbox'
        'ps'
        'switch'
    --]] --> TODO: Make sure to rename the brands in the 
    self.brand = 'generic'

    --]] Runtime
    local brand_from_newest = 'generic'
    self.runtime = userInputService.InputBegan:Connect(function(key, gp)
        if table.find(gamepad_inputs, key.KeyCode) then
            --] Gamepad
            if self.platform ~= 'console' then
                print(`[{script.Name}] New input type detected: Console`)
                self.platform = 'console'
                userInputService.MouseIconEnabled = true
            end

            local stringKcPressed = userInputService:GetStringForKeyCode(key.KeyCode)
            for platform: string, values in pairs(binding_data.return_values) do
                if table.find(values, stringKcPressed) then
                    brand_from_newest = platform
                end
            end

            if brand_from_newest ~= self.brand then
                self.brand = brand_from_newest
                print(`[{script.Name}] Brand: {self.brand}`)
            end
        elseif key.UserInputType == Enum.UserInputType.Touch then
            --] Mobile
            if self.platform ~= 'mobile' then
                print(`[{script.Name}] New input type detected: Mobile`)
                self.platform = 'mobile'
                self.brand = 'generic'
                userInputService.MouseIconEnabled = false
            end
        else
            --] KBM
            if self.platform ~= 'desktop' then
                print(`[{script.Name}] New input type detected: Desktop`)
                self.platform = 'desktop'
                self.brand = 'generic'
                userInputService.MouseIconEnabled = true
            end
        end
    end)

    return self
end

return platform