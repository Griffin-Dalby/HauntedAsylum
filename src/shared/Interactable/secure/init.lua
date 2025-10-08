--[[

    Interaction Security Tracker

    Griffin Dalby
    2025.09.09

    This module will provide centralized & efficient logic to track players
    and determine interaction availability.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local flagger = require(script.flagger)
local interactable_types = require(replicatedStorage.Shared.Interactable.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local interactable_cache = cache.findCache('interactable')
local objects_cache = interactable_cache:hasEntry('objects')
    and interactable_cache:findTable('objects')
    or interactable_cache:createTable('objects')

--]] Settings
local __debug = false

local flagger_player_data = {
    no_character = true,
}

local flagger_object_data = {

}

local flagger_prompt_data = {
    
}

local flagger_instance_data = {
    out_of_range = true,
}

--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
function stagger(every: number, fn: (delta: number) -> nil) : RBXScriptConnection
    local t=0
    local conn = runService.Heartbeat:Connect(function(deltaTime)
        t+=deltaTime
        if t<=every then return end
        t=0

        fn(deltaTime)
    end)

    return conn
end

--]] Module
local secure = {}
secure.__index = secure

type self = {
    player_flaggers: {[Player]: flagger.Flagger},

    runtime: {
        range: RBXScriptConnection
    },

    events: {
        player_added: RBXScriptConnection,
        player_remove: RBXScriptConnection
    }
}
export type InteractionSecurer = typeof(setmetatable({} :: self, secure))

--[[ secure.new()
    This will return a new InteractionSecurer and initalize the runtimes
    needed to decide player interaction availability. ]]
function secure.new() : InteractionSecurer
    local self = setmetatable({} :: self, secure)

    self.player_flaggers = {}
    local function add_player_flagger(player: Player, override: boolean)
        if self.player_flaggers[player] then
            if not override then
                error(`Attempt to add_player_flagger to an occupied index without override! (Player: {player.Name}.{player.UserId})`)
            else
                self.player_flaggers[player]:destroy()
            end
        end
        self.player_flaggers[player] = flagger.new(flagger_player_data) end
    local function rm_player_flagger(player: Player)
        if self.player_flaggers[player] then
            self.player_flaggers[player]:destroy()
            self.player_flaggers[player] = nil
        end
    end

    if is_client then
        add_player_flagger(players.LocalPlayer)
    end

    --]] Runtimes
    self.runtime = {}

    --> Physical
    --#region
    local function check_physical(player: Player)
        local player_flagger = self.player_flaggers[player]
            
        --> Check character
        --#region
        local character = player.Character
        local root_part = character and character.PrimaryPart or nil

        local player_exists = character~=nil and root_part~=nil --> Character existence check
        player_flagger:setFlag('no_character', not player_exists)
        if __debug then print(`no_character: {not player_exists}`) end
        if not player_exists then return end

        local root_pos = root_part.Position

        --#endregion

        --> Check objects/prompts
        for _, object: interactable_types.InteractableObject in pairs(objects_cache:getContents()) do
            if not player_flagger:hasChild(object.object_id) then
                player_flagger:newChild(object.object_id, flagger_object_data)
            end
            local object_flagger = player_flagger:findChild(object.object_id)
            
            --> Range
            for _, prompt in pairs(object.prompts) do
                if not object_flagger:hasChild(prompt.prompt_id) then
                    object_flagger:newChild(prompt.prompt_id, flagger_prompt_data)
                end
                local prompt_flagger = object_flagger:findChild(prompt.prompt_id)
                
                for _, instance in pairs(prompt.attached_instances) do
                    if not prompt_flagger:hasChild(instance) then
                        prompt_flagger:newChild(instance, flagger_instance_data)
                    end
                    local instance_flagger = prompt_flagger:findChild(instance)
                    
                    local object_root = if instance:IsA('Model') then instance.PrimaryPart else instance
                    if not object_root or not object_root['Position'] then continue end
                    
                    local dist = (root_pos-object_root.Position).Magnitude
                    
                    local in_range = dist<prompt.prompt_defs.range --> Character in-range check
                    instance_flagger:setFlag('out_of_range', not in_range)
                    if __debug then print(`out_of_range: {not in_range}`) end
                    if not in_range then continue end
                end


            end
        end
    end
    self.runtime.physical = stagger(.33, function(deltaTime)
        if is_client then
            check_physical(players.LocalPlayer)
        else
            for _, player: Player in pairs(players:GetPlayers()) do
                check_physical(player)
            end
        end
    end)

    --#endregion

    --]] Events
    self.events = {}
    if not is_client then
        self.events.player_added = players.PlayerAdded:Connect(add_player_flagger)
        self.events.player_remove = players.PlayerRemoving:Connect(rm_player_flagger)
    
        for _, player: Player in pairs(players:GetPlayers()) do
            add_player_flagger(player) end --> Get early joiners
    end

    return self
end

return secure