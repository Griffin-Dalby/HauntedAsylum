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
local state_types = require(replicatedStorage.Sawdust.__impl.states.types)

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
        local self = entity.new(script.Name, 
        {       --] Sense Packages
            player = {
                blacklist = {},
                filterType = 'exclude',
                sessionDataFlags = {'is_hiding'}
            },

            physical = {

            }
        }, {    --] Behavior Parameters
            ['curiosity'] = {def=.25, lim={min=.1, max=.5}, weights={
                lost_sight = '+.025',
            }}
        }) :: entity.Entity<{}> & {
            patrol: state_types.SawdustState<entity.FSM_Cortex, {}>
        }

        --] Define States

        --> Generic States
        --#region
        self.idle
            :hook('enter', 'c_enter', function(env)
                print('in idle')
                
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env: typeof(self.idle.environment))
                if is_client then
                    
                else
                    local closest = env.shared.senses.player:findPlayersInRadius(15)
                        .enforceSDF('is_hiding', false)
                        .closest().player :: Player

                    env.shared.target = (closest~=nil) and closest.Character.PrimaryPart or nil
                    
                end
            end)
        self.idle:transition('chase'):when(function(env)
            return env.shared.target ~= nil end)

        self.chase
            :hook('enter', 'c_enter', function(env)
                print('in chase')
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
                local sense_player, sense_physical = 
                    env.shared.senses.player,
                    env.shared.senses.physical
                
                if is_client then

                else
                    if not env.shared.target then return end
                    local t_root = env.shared.target :: BasePart
                    local dist = sense_physical:getDistance(t_root.Position)
                    local p = sense_player:getPlayerFromRoot(t_root)
                    
                    local is_hiding = sense_player:adheresSDF(p, 'is_hiding', false, true) --> 'is_hiding' ~= false

                    if dist <= 7.5 and is_hiding then
                        env.shared.target = nil --> Lost target due to hiding
                        env.shared.learn:process('lost_sight')
                        self.fsm:switchState('patrol')
                    elseif dist > 7.5 and is_hiding then
                        
                    end
                end
            end)


    
        --#endregion

        --> Entity States
        --#region
        self.patrol = self.fsm:state('patrol')
            :hook('enter', 'c_enter', function(env: typeof(self.patrol.environment))
                print('in patrol')
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env: typeof(self.patrol.environment))
                
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