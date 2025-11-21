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
local perception_distance = 15

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
    spawn_points = { workspace:WaitForChild('EntitySpawn', 25) },

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
            --// TODO: Add more behavior weights & actions to call on them, adjust weights.
            
            --] Mental
            ['curiosity'] = {def=.25, lim={min=.1, max=.5}, weights={
                found_target = '-.025',
                lost_target = '+.03',

                -- heard_noise = '+.03'
            }}, --> curiosity: Entity slows down and checks out hotspots, or events.
            ['awareness'] = {def=.1, lim={min=.1, max=.75}, weights={
                found_target = '-.035',
                lost_target = '+.0225',

                -- heard_noise = '+.02'
            }}, --> awareness: Entity is more aware of events and players.
            
            --] Emotional
            ['patience'] = {def=.35, lim={min=.1, max=.65}, weights={
                found_target = '+.05',
                lost_target = '-.055',

                -- heard_noise = '-.025'
            }}, --> patience: Entity is careful & focused about what they're doing.
            ['stress'] = {def=.05, lim={min=.05, max=1}, weights={
                found_target = '-.035',
                lost_target = "+.045",

                -- heard_noise = '+.03'
            }}, --> stress: Entity is more ruthless & agressive
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
                    local closest = env.shared.senses.player:findPlayersInRadius(perception_distance)
                        .enforceSDF('is_hiding', false)
                        .closest().player :: Player

                    env.shared.target = (closest~=nil) and closest.Character.PrimaryPart or nil
                    -- if env.shared.target~=nil then
                    --     self.fsm:switchState('chase')
                    -- end
                end
            end)
        self.idle:transition('chase'):when(function(env)
            return env.shared.target ~= nil end)

        self.chase
            :hook('enter', 'c_enter', function(env)
                
                if is_client then
                    -- local c_target =
                    -- local c_target_p = players:GetPlayerFromCharacter(c_target.Parent)
                    -- if c_target_p~=players.LocalPlayer then return end
                    
                else
                    env.shared.learn:process('found_target')
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
                    local can_see = sense_player:canSee(p) --//TODO: Implement this (w/ raycast)

                    local track_distance = (perception_distance/2)
                        * (.65+env.shared.learn:getParam('awareness'))

                    if not can_see then --//TODO: Flesh out entity tree
                        --> Entity cannot currently see player
                        local out_of_track = dist>track_distance

                    end
                end
            end)


    
        --#endregion

        --> Entity States
        --#region

        self.patrol = self.fsm:state('patrol') --//TODO: Patrol wandering behavior
            :hook('enter', 'c_enter', function(env: typeof(self.patrol.environment))
                --> Choose best fits
                
            end)

        self.patrol_investigate = self.fsm:state('patrol_investigate') --//TODO: Patrol Investigation behavior
            :hook('enter', 'c_enter', function(env)
            
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env)
            
            end)

        self.patrol_search = self.fsm:state('patrol_search')
            :hook('enter', 'c_enter', function(env)
            
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env)
            
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