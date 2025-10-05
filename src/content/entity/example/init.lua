--[[

    Entity Example Data

    Griffin Dalby
    2025.09.16

    This module will show an example for entity data.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local players = game:GetService('Players')

--]] Modules
local entity = require(replicatedStorage.Shared.Entity)

--]] Sawdust
--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Entity

local __entity = require(script.Parent.__entity)
local example = {} :: __entity.EntityTemplate

example.appearance = {
    model = script.example,
    name = 'Example'
}

example.behavior = {
    spawn_points = { workspace:WaitForChild('EntitySpawn') },

    instantiate = function()
        local self = entity.new(script.Name)

        --] Define States
        --#region
        self.idle
            :hook('enter', function(env)
                print('idle')
            end)
            :hook('exit', function(env)
                
            end)
            :hook('update', function(env)
                
            end)

        self.chase
            :hook('enter', function(env)
                print('chase')
            end)
            :hook('exit', function(env)
                
            end)

        --#endregion

        return self
    end,

    find_target = function(env: {}, model: Model)
        local c_target = env.target
        local is_chasing = c_target~=nil

        local root_part = model.PrimaryPart
        local player_list = players:GetPlayers()
        local last_max = {48*(is_chasing and 1 or .5), c_target}
        for _, player: Player in pairs(player_list) do
            if not player.Character then continue end
            local target_root = player.Character.PrimaryPart

            local dist = (target_root.Position-root_part.Position).Magnitude
            if dist < last_max[1] then
                last_max = {dist, target_root} end
        end

        if last_max[2] == nil then
            return end
        return last_max[2]
    end
}

example.data = {
}

return example