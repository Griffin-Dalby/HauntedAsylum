--[[

    BrainView Plugin

    Griffin Dalby
    2025.11.04

    This plugin will allow developers of "Gonjiam: Haunted Asylumn" to
    access & view entity parameters during runtime, as well as exporting
    parameter data for the main brain.

--]]

--]] Services
local runService = game:GetService('RunService')
local repFirst = game:GetService('ReplicatedFirst')
local players = game:GetService('Players')

local s = pcall(function()
    return runService:IsEdit() end)
if not s then return end

--]] Modules
--]] Settings
--]] Constants
--]] Variables
--]] Functions
function safeFind(i: Instance, name: string, construct: () -> Instance)
    local found = i:FindFirstChild(name)
    if not found then
        found = construct()
        found.Name = name
        found.Parent = i
    end

    return found
end

--]] Plugin
if runService:IsRunning() then --]] Runtime Injection

    local tools_f = repFirst:FindFirstChild('__tools')
    if not tools_f then return end

    local brainView_data = tools_f:FindFirstChild('brainview')
    if not brainView_data then return end

    if brainView_data:FindFirstChild('enabled').Value~=true then return end
    print(brainView_data.enabled.Value)

    local is_server = runService:IsServer()
    local logic = if is_server then script.server_logic else script.client_logic

    if is_server then
        logic.Enabled = false
        logic = logic:Clone()

        logic.Name = `BrainView-Server`
        logic.Parent = game:GetService('ServerScriptService')
        
        logic.Enabled = true
    else
        require(logic)()
    end


else --]] Plugin Setup

    --> Setup env
    local tools_f = safeFind(repFirst, '__tools', function()
        return Instance.new('Folder') end) :: Folder 

    local brainView_data = safeFind(tools_f, 'brainview', function()
        local f = Instance.new('Folder')

        Instance.new('BoolValue', f).Name = 'enabled'

        return f
    end) :: Folder

    --> Toolbar
    local toolbar = plugin:CreateToolbar('Gonjiam Tools')
    local toggle = toolbar:CreateButton('Toggle BrainView', 'If enabled, BrainView UI will be shown in run mode.', 'rbxassetid://115504474439454')

    toggle.Click:Connect(function(...: any)  
        if runService:IsRunning() then
            warn(`[{script.Name}] BrainView cannot be toggled during runtime!`)
            return end

        local is_enabled = brainView_data:FindFirstChild('enabled') :: BoolValue
        is_enabled.Value = not is_enabled.Value

        print(`[{script.Name}] BrainView is now {is_enabled.Value and
            `Enabled, UI will open when game runs.` or 'Disabled'}.`)
    end)
    
end