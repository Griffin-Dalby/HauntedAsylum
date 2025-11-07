--[[

    BrainView Logic

    Griffin Dalby
    2025.11.04

    This script provides client logic for the BrainView plugin.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local BVUI = require(script.BrainViewUI)

--]] Settings
--]] Constants
--]] Variables
local entity_data = {}
local this_ui

--]] Functions
function parseParameterUpdate(entity_id: string, delta_id: number, delta_data: {})
    if not this_ui then return end
    
    local param_data = entity_data[entity_id].parameter
    if param_data[delta_id] then
        warn(`[{script.Name}] Attempt to update paramater @ delta {delta_id}! This delta is already indexed.`)
        return end

    param_data[delta_id] = delta_data
    this_ui:renderParameters(param_data)
end

local update_map = {
    ['parameter'] = parseParameterUpdate
}

--]] Logic
return function()
    print(`[BrainView] Tool Enabled! Establishing server connection.`)

    --> Locate Endpoint
    local timeout = false
    task.delay(5, function() timeout = true; end)

    repeat task.wait(0) until replicatedStorage:FindFirstChild('__brainview_metrics') or timeout
    if timeout then
        error(`[BrainView] Tool Failed! Unable to establish server connection.`)
    end

    --> Connect to Endpoint
    local netBrainView = replicatedStorage:FindFirstChild('__brainview_metrics') :: RemoteEvent
    netBrainView.OnClientEvent:Connect(function(identity: {}, data_id: number, data: {}) 
        local entity_id: string, update_id: string = unpack(identity)
        if not entity_data[entity_id] then
            entity_data[entity_id] = {
                parameter = {}
            }
        end

        local updater = update_map[update_id]
        if updater then
            updater(entity_id, data_id, data)
        end
    end)
    
    print(`[BrainView] Server connection established!`)
    
    --> Create UI
    this_ui = BVUI.new()
end