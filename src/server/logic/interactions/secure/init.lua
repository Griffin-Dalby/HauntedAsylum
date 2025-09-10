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

--]] Settings
local flagger_player_data = {
    no_character = true,
}

local flagger_object_data = {
    out_of_range = true,
}

local flagger_prompt_data = {

}

--]] Constants
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

    --]] Runtimes
    local objects_cache = interactable_cache:hasEntry('objects') 
        and interactable_cache:findTable('objects')
        or interactable_cache:createTable('objects')

    self.runtime = {}
    self.runtime.physical = stagger(.33, function(deltaTime)
        for _, player: Player in pairs(players:GetPlayers()) do
            local player_flagger = self.player_flaggers[player]
            
            --> Check character
            --#region
            local character = player.Character

            if not character then
                player_flagger:setFlag('no_character', true)
                continue end

            local root_part = character.PrimaryPart
            if not root_part then
                player_flagger:setFlag('no_character', true)
                continue end
            player_flagger:setFlag('no_character', false)
            local root_pos = root_part.Position

            --#endregion

            --> Check objects/prompts
            for _, object: interactable_types.InteractableObject in pairs(objects_cache:getContents()) do
                if not player_flagger:hasChild(object.object_id) then
                    player_flagger:newChild(object.object_id, flagger_object_data)
                end
                local object_flagger = player_flagger:findChild(object.object_id)

                --> Range
                local object_root = object.instance:IsA('Model') and object.instance.PrimaryPart or object.instance
                local dist = (root_pos-object_root.Position).Magnitude

                for _, prompt in pairs(object.prompts) do
                    if not object_flagger:hasChild(prompt.action) then
                        object_flagger:newChild(prompt.action, flagger_prompt_data)
                    end
                    local prompt_flagger = object_flagger:findChild(prompt.action)

                    print(dist<prompt.prompt_defs.range)
                end
            end

        end
    end)

    --]] Events
    self.events = {}
    self.events.player_added = players.PlayerAdded:Connect(add_player_flagger)
    self.events.player_remove = players.PlayerRemoving:Connect(rm_player_flagger)

    for _, player: Player in pairs(players:GetPlayers()) do
        add_player_flagger(player) end --> Get early joiners

    return self
end

return secure