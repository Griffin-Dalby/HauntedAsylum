--[[

    Client Interactions Logic

    Griffin Dalby
    2025.09.10

    This script will handle all object & prompt registration for the
    client, acting as the main hub for runtimes and replication.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local __interactable = replicatedStorage.Shared.Interactable

local interactable = require(__interactable)
local __secure = require(__interactable.secure)
local __flagger = require(__interactable.secure.flagger)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

-- Networking

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script

local secure = __secure.new()

--> Setup PromptUIs
for _, prompt_ui_data: ModuleScript in pairs(script.promptUis:GetChildren()) do
    if not prompt_ui_data:IsA('ModuleScript') then continue end
    local generator = require(prompt_ui_data)

    generator()
end

--> Setup Objects
for _, object_data: ModuleScript in pairs(script.objects:GetChildren()) do
    if not object_data:IsA('ModuleScript') then continue end
    local generator = require(object_data)

    generator()
end

--> Prompt Enabler Runtime
local player_flagger = secure.player_flaggers[players.LocalPlayer]
local enabled_prompts = {}

runService.Heartbeat:Connect(function(deltaTime)
    local updates = {}

    --> Check for enables
    for object_id, object_flagger in pairs(player_flagger.children) do
        for prompt_id, prompt_flagger in pairs(object_flagger.children) do
            local prompt_visible = prompt_flagger:isClean()
            if not prompt_visible then break end
            
            local object = interactable.findObject(object_id)
            local prompt = object.prompts[prompt_id]
            local upd_str = `{object_id}*{prompt_id}`

            if not enabled_prompts[upd_str] then
                prompt:enable()
                enabled_prompts[upd_str] = prompt
            end

            updates[upd_str] = true
        end
    end

    --> Check for disables
    for upd_str: string, prompt in pairs(enabled_prompts) do
        if not updates[upd_str] then
            prompt:disable()
            enabled_prompts[upd_str] = nil
        end
    end
end)