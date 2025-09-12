--[[

    Client Interactions Logic

    Griffin Dalby
    2025.09.10

    This script will handle all object & prompt registration for the
    client, acting as the main hub for runtimes and replication.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local userInputService = game:GetService('UserInputService')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local __interactable = replicatedStorage.Shared.Interactable

local interactable = require(__interactable)
local __secure = require(__interactable.secure)
local __flagger = require(__interactable.secure.flagger)
local __intbl_types = require(__interactable.types)

local __platform = require(script.platform)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

-- Networking

--]] Settings
--]] Constants
--]] Variables
local l_objects = {} --> TODO: Double-check if this is needed, and refactor accordingly.

--]] Functions
local function count_dir(d: {})
    local i=0
    for _ in d do i+=1 end
    return i
end

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
    local gen_obj = require(object_data)()
    l_objects[gen_obj.object_id] = gen_obj
end

--> Prompt Enabler Runtime
local player_flagger = secure.player_flaggers[players.LocalPlayer]
local enabled_prompts = {}
local selected_prompt = {0, nil, ''}

runService.Heartbeat:Connect(function(deltaTime)
    local updates = {}

    --> Check for enables
    for object_id, object_flagger in pairs(player_flagger.children) do
        for prompt_id, prompt_flagger in pairs(object_flagger.children) do
            for instance: Instance, instance_flagger in pairs(prompt_flagger.children) do
                local prompt_visible = instance_flagger:isClean()
                if not prompt_visible then continue end
                
                local object = interactable.findObject(object_id)
                local prompt = object.prompts[prompt_id]

                if not enabled_prompts[instance] then
                    print(`enable inst`)
                    prompt:enable(instance)
                    enabled_prompts[instance] = prompt
                end

                updates[instance] = prompt
            end
        end
    end

    --> Check for disables
    for instance: Instance, prompt in pairs(enabled_prompts) do
        if not updates[instance] then
            print('disable inst')
            prompt:disable()
            enabled_prompts[instance] = nil
        end
    end

    --> Check update z-index
    local update_count = count_dir(updates)

    if update_count==0 then
        return end

    for instance, prompt in pairs(updates) do --> Locate closest index
        if not prompt.prompt_ui.zindex then continue end

        local zindex = prompt.prompt_ui.zindex
        if (zindex < selected_prompt[1]) and (update_count>1) then continue end
        selected_prompt = {zindex, prompt, instance} end
    
    if not selected_prompt[2] then return end
    selected_prompt[2]:setTargeted(true)
    selected_prompt[1] = 0

    updates[selected_prompt[3]] = nil --> Remove from "updates", we'll disable these.
    for _, prompt in pairs(updates) do
        prompt:setTargeted(false)
    end
end)

--> Prompt Input Processor
local platform = __platform.new()

userInputService.InputBegan:Connect(function(key, gp)
    if gp then return end

    local prompt = selected_prompt[2] :: __intbl_types.InteractablePrompt
    if selected_prompt[2]==nil then return end

    --> Check bind
    local binds = selected_prompt[2].prompt_defs.interact_bind
    local platform_bind = binds[platform.platform]
    if (key.KeyCode~=platform_bind)
        and (key.UserInputType~=platform_bind) then
            return end
            
    --> Trigger prompt
    prompt:trigger()
end)