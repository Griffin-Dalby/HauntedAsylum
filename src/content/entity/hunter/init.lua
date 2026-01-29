--[[

    Hunter Entity Behavior

    Griffin Dalby
    2026.1.24

    This module provides behavior charts for the "Hunter" entity.


    The "Hunter" is an active pursuit entity that relentlessly chases
    players. Creates tensition through persistent hunting behavior.

--]]

--]] Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--]] Modules
local IEntity = require(ReplicatedStorage.Shared.Entity)

--]] Sawdust

--]] Settings
local is_client = RunService:IsClient()

--> Debug Options
local DEBUG_THOUGHTS = true

--]] Constants
--]] Variables
--]] Functions
--]] Entity

local __entity = require(script.Parent.__entity)
local Hunter = {} :: __entity.EntityTemplate

Hunter.appearance = {
    model = script.hunter,
    name = "Hunter"
}

Hunter.behavior = {
    spawn_points = {},

    instantiate = function()
        --> Create Asylum Mapping

        --> Create Entity
        local self = IEntity.new(script.Name,
            {
                player = {
                    blacklist = {},
                    filterType = 'exclude',
                    sessionDataFlags = { 'is_hiding' }
                },

                physical = {
                    
                },

                asylum = {

                }
            }, 
            {
                --] Mental
                ['awareness'] = {def=.4, lim={min=.2, max=.7}, weights = {
                    spotted_player = '+.08',
                    lost_player = '-.05',
                    
                    maintained_chase = '-.1',
                    gave_up = ''
                }},

                ['curiosity'] = {def=.3, lim={min=.1, max=.7}, weights={
                    spotted = '-.04',
                    observation_completed = '+.05',

                    player_evasion = '+.03'

                }},
                
            }
        ) :: IEntity.Entity<{
            
        }> & {

        }

        --] Extract Types
        type FSM_Cortex = typeof(self.fsm.environment) & {
            recent_rooms: { [string]: number } --> [room_id]: timestamp

        }
        type idle_env   = typeof(self.idle.environment) & {
            current_floor:   number,
            current_room:    string,
            current_section: string?,
        }

        --] Define States

        --> Generic States
        --#region
        self.idle
            :hook('enter', 'c_enter', function(env: idle_env)
                if is_client then
                else
                    print("Hunter Idle")

                    --> Default Position
                    if not env.current_floor or not env.current_room then
                        env.current_floor = math.random(1,2)
                        env.current_room = 'ward1'
                    end
                    
                    --] Find Possible Rooms
                    local possible_rooms: { [Part]: number, } = {}

                    --> Include Sections in Rooms
                    local room_sections = {}
                    local mapping_data = env.shared.senses.asylum:GetSortedMappings()

                    local room_data = mapping_data[env.current_floor][env.current_room]
                    if room_data.room then
                        room_sections['main'] = room_data.room
                    else
                        for i, room in pairs(room_data) do
                            if i=="connections" then continue end
                            room_sections[i] = room.room
                        end
                    end
                    print(room_sections)

                    --> Include Connected Rooms
                    -- local connected_rooms = env.shared.senses.asylum:GetConnectedRooms(
                    --     env.current_floor, env.current_room, env.current_section)

                    --] Weight Options
                    

                    
                end
            end)

        --#endregion

        return self
    end
}

return Hunter