--[[

    Entity Example Data

    Griffin Dalby
    2025.09.16

    This module will show an example for entity data.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')

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
        local self: entity.Entity<{test: string}> = entity.new(script.Name, {
            player = {
                blacklist = {},
                filterType = 'exclude',
                sessionDataFlags = {'is_hiding'}
            },

            physical = {

            }
        }, {
            ['curiosity'] = {def=.25, lim={min=.1, max=.5}, adj=function()
                
            end}
        })

        --] Define States
        --#region
        self.idle
            :hook('enter', 'c_enter', function(env)
                
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env: typeof(self.idle.environment))
                if is_client then
                    
                else
                    local closest = env.shared.senses.player:findPlayersInRadius(15)
                        :enforceSDF('is_hiding', false)
                        :closest().player :: Player

                    env.shared.target = (closest~=nil) and closest.Character.PrimaryPart or nil
                end
            end)

        self.chase
            :hook('enter', 'c_enter', function(env)
                print('chase')
                if is_client then
                    -- local c_target =
                    -- local c_target_p = players:GetPlayerFromCharacter(c_target.Parent)
                    -- if c_target_p~=players.LocalPlayer then return end
                    
                else

                end
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env: typeof(self.chase.environment))
                local sense_player, sense_physical = unpack{
                    env.shared.senses.player,
                    env.shared.senses.physical}
                
                if is_client then

                else
                    if not env.shared.target then return end
                    local t_root = env.shared.target :: BasePart
                    local dist = sense_physical:getDistance(t_root)
                    local p = sense_player:getPlayerFromRoot(t_root)
                    
                    local is_hiding = sense_player:adheresSDF(p, 'is_hiding', true)

                    if dist > 7.5 and is_hiding then
                        env.shared.target = nil --> Lost target due to hiding
                    end
                end
            end)

        --#endregion

        return self
    end,

    find_target = function(env: entity.FSM_Cortex, model: Model)
        
    end
}

example.data = {
}

return example