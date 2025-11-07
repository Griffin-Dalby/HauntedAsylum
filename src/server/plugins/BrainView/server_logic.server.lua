--[[

    BrainView Server Logic

    Griffin Dalby
    2025.11.04

    This script provides server logic for the BrainView plugin.

--]]

if script.Name ~= 'BrainView-Server' then return end

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

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

--]] Logic
print(`[BrainView] Tool Enabled! Establishing networking endpoints...`)

--> Establish Networking
local metrics_event: RemoteEvent = safeFind(replicatedStorage, '__brainview_metrics', function()
    return Instance.new('RemoteEvent') end)