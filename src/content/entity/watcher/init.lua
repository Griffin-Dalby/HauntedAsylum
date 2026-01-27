--[[

    Watcher Entity Behavior

    Griffin Dalby
    2026.1.21

    This module provides behavior definitons for the "Watcher" entity.


    The "Watcher" is a curious, observant, and passive entity that simply
    spawns at player's frequented spots, and watches them from a distance.

    This entity disappears a little after being spotted, and simply acts
    as a ambient scare.

--]]

--]] Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService('RunService')
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--]] Modules
local entity = require(ReplicatedStorage.Shared.Entity)
local state_types = require(ReplicatedStorage.Sawdust.__impl.states.types)

--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)

local Networking = Sawdust.core.networking

--> Networking
local WorldChannel = Networking.getChannel("world")

--]] Settings
local DEBUG_POSITION_RAYS = false
local DEBUG_SIGHT_RAYS = false

local MAX_POSITION_DISTANCE = 35
local MIN_POSITION_DISTANCE = 10

local RAY_COUNT = 30

local perception_distance = 15

--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Entity

local cast_info = RaycastParams.new()
cast_info.FilterDescendantsInstances = {workspace:WaitForChild('Build')}
cast_info.FilterType = Enum.RaycastFilterType.Include

local __entity = require(script.Parent.__entity)
local Watcher = {} :: __entity.EntityTemplate

Watcher.appearance = {
    model = script.watcher,
    name = 'Watcher'
}

Watcher.behavior = {
    spawn_points = { workspace:WaitForChild('EntitySpawn', 25) },

    instantiate = function()
        local self = entity.new(script.Name, 
        { --] Sense Packages
            player = {
                blacklist = {},
                filterType = 'exclude',
                sessionDataFlags = {'is_hiding'}
            },

            physical = {

            }
        }, { --] Behavior Parameters
            --// TODO: Add more behavior weights & actions to call on them, adjust weights.
            
            --] Mental

            --> curiosity: How often this entity appears due to player activity.
            ['curiosity'] = {def=.3, lim={min=.1, max=.7}, weights={
                spotted = '-.04',
                observation_completed = '+.05',

                player_evasion = '+.03'

            }},

            --> awareness: How far this entity appears from player
            ['awareness'] = {def=.5, lim={min=.3, max=.8}, weights={
                spotted = '-.05',
                observation_completed = '+.03',

                player_evasion = '+.05'
            }},
            
            --] Emotional

            --> patience: How long this entity is willing to "watch"
            ['patience'] = {def=.6, lim={min=.3, max=.9}, weights={
                spotted = '+0.04',
                observation_completed = '-.06',

                player_evasion = '+.05'

                -- heard_noise = '-.025'
            }},
            
            --] Social

            --> communication: How likely this entity will tell others about a completed observation
            ['communication'] = {def=.2, lim={min=0, max=.8}, weights={
                spotted = '+.15',
                observation_completed = '+.2',

                player_evasion = '-.4'
            }}

        }) :: entity.Entity<{ 
            last_manifestation_tick: number?
        }> & {
            positioning: state_types.SawdustState<FSM_Cortex, {}>,
            observing: state_types.SawdustState<FSM_Cortex, {
                started_observing: number,
                watch_cast_info: RaycastParams?,

                watch_cast_tick: number,
                ticks_evaded: number,
                is_evading: boolean,
            }>
        }

        --] Extract Types
        type FSM_Cortex = typeof(self.fsm.environment) & {
            observe_target_p: Player?,
            observe_target: Model?, 
            observe_position: {[number]: Vector3},

            pressure: number
        }
        type idle_env        = typeof(self.idle.environment)
        type positioning_env = typeof(self.positioning.environment)
        type observing_env   = typeof(self.observing.environment)

        --] Define States

        --> Generic States
        --#region
        self.idle
            :hook('enter', 'c_enter', function(env)
                if is_client then
                else
                    env.shared.observe_target = nil
                    env.shared.observe_target_p = nil
                    env.shared.observe_position = nil

                    env.shared.pressure = 0

                    --> Despawn Model
                    if self.rig.model then
                        self.rig:despawn()
                    end

                end
            end)
            :hook('update', 'c_update', function(env: FSM_Cortex & idle_env)
                if is_client then
                else
                    --> Get Params
                    local curiosity = env.shared.learn:getParam("curiosity") --> Affects check freq. and manifestation probability

                    --> Run on Clock
                    local this_tick = tick()
                    if not env.last_manifestation_tick then
                        env.last_manifestation_tick = tick()
                        return
                    else
                        local manifestation_time = (curiosity.limit.max+1)-curiosity.value 
                        
                        if this_tick-env.last_manifestation_tick < 1*manifestation_time then
                            return
                        end

                        env.last_manifestation_tick = this_tick
                    end

                    --> Run manifestation chance
                    local manifest_chance = math.random()
                    -- print(`Manifest Chance: {manifest_chance} <= {curiosity.value}: ({manifest_chance<=curiosity.value})`)
                    local do_manifest = manifest_chance<=curiosity.value

                    if do_manifest then
                        self.fsm:switchState("positioning")
                    end
                end
            end)

        --#endregion

        --> Entity States
        --#region

        self.positioning = self.fsm:state('positioning')
            :hook('enter', 'c_enter', function(env: FSM_Cortex & positioning_env)
                if is_client then return end
                
                --]] Step 1: Find Target
                local player_list = Players:GetPlayers()
                local random_player = player_list[math.random(1, #player_list)]
                local player_character = random_player.Character

                --]] Step 2: Find Position
                local look_direction: Vector3, _yaw: number = unpack(env.shared.senses.player:getPlayerLookDirection(random_player))

                local eligible_casts = {}
                for degs=0, math.pi*2, (math.pi*2)/RAY_COUNT do
                    local origin = CFrame.new(player_character.PrimaryPart.Position) * CFrame.Angles(0, degs, 0)
                    local direction = origin + origin.LookVector*MAX_POSITION_DISTANCE
                    local dot_product = look_direction:Dot(direction.LookVector)
                    if dot_product>0.5 then continue end

                    local cast = workspace:Raycast(origin.Position, origin.LookVector*MAX_POSITION_DISTANCE, cast_info)

                    if cast then
                        table.insert(eligible_casts, cast)

                        if DEBUG_POSITION_RAYS then
                            local cast_part = Instance.new("Part")
                            cast_part.Name = `deg_ray_{degs}`
                            cast_part.Anchored, cast_part.CanCollide = true, false
                            cast_part.Material, cast_part.Color = Enum.Material.Neon, Color3.new(0, 1, 0)
                            cast_part.Transparency = .75

                            cast_part.CFrame = CFrame.lookAt(origin:Lerp(direction, .5).Position, direction.Position)
                            cast_part.Size = Vector3.new(.1, .1, 25)
                            cast_part.Parent = workspace.Terrain

                            Debris:AddItem(cast_part, 4)
                        end
                    end
                end

                --]] Step 3: Score Parameters based off Awareness.
                --> Higher Awareness: Prefers further spots

                local awareness = env.shared.learn:getParam('awareness').value

                --> Calculate Weight
                local min_dist = math.huge
                local max_dist = 0
                for score: number, cast in ipairs(eligible_casts) do
                    min_dist = math.min(min_dist, cast.Distance)
                    max_dist = math.max(max_dist, cast.Distance)
                end

                local scored_positions = {}
                local total_weight = 0

                for i, cast in ipairs(eligible_casts) do
                    local normalized = (cast.Distance-min_dist)/(max_dist-min_dist)
                    local score = awareness*normalized+(1-awareness)*(1-normalized)

                    total_weight += score
                    table.insert(scored_positions, {
                        position = cast.Position,
                        distance = cast.Distance,
                        normal = cast.Normal,
                        weight = score
                    })
                end

                --> Select Randomly
                local rand = math.random() * total_weight
                local cumulative = 0
                local chosen_position: Vector3, chosen_normal: number

                for _, data in ipairs(scored_positions) do
                    cumulative+=data.weight
                    if rand <= cumulative then
                        chosen_position = data.position
                        chosen_normal = data.normal
                        break
                    end
                end

                --]] Step 4: Spawn
                if chosen_position then
                    print(`[{script.Name}] I have chosen to watch "{random_player.Name}#{random_player.UserId}"`)

                    local rig_model = self.rig.model
                    local prim_part = rig_model.PrimaryPart
                    local down_cast = workspace:Raycast(chosen_position, -Vector3.new(0, 5, 0), cast_info)

                    local origin_position = if down_cast 
                        then down_cast.Position+Vector3.new(0, prim_part.Size.Y+prim_part.Size.Y)
                        else chosen_position

                    env.shared.observe_target = player_character
                    env.shared.observe_target_p = random_player
                    env.shared.observe_position = {origin_position, chosen_normal}

                    self.rig:spawn(origin_position+Vector3.new(prim_part.Size.X, 0, prim_part.Size.Z))
                    self.fsm:switchState('observing')
                else
                    self.fsm:switchState('idle')
                end
            end)
            :hook('update', 'c_exit', function(env: FSM_Cortex & positioning_env)
                
            end)

        self.observing = self.fsm:state('observing')
            :hook('enter', 'c_enter', function(env : FSM_Cortex & observing_env)
                if is_client then return end
                if not env.shared.observe_target then
                    warn(`[{script.Name}] Failed to find observe target! Falling back into idle.`)
                    self.fsm:switchState('idle')
                return end

                env.started_observing = tick()
                env.pressure = 0

                --> Generate Cast Info
                local watch_cast_info = RaycastParams.new()
                watch_cast_info.FilterDescendantsInstances = { workspace:WaitForChild('Build') }
                watch_cast_info.FilterType = Enum.RaycastFilterType.Include

                env.watch_cast_info = watch_cast_info

                env.watch_cast_tick = 0
                env.ticks_evaded = 0
                env.is_evading = false
            end)
            :hook('exit', 'c_exit', function(env)
                
            end)
            :hook('update', 'c_update', function(env : FSM_Cortex & observing_env)
                local patience = env.shared.learn:getParam('patience').value

                --> Ensure Target
                local observe_target = env.shared.observe_target :: Model?
                if not observe_target then
                    warn(`[{script.Name}] Failed to find observe target! Falling back into idle.`)
                    self.fsm:switchState('idle')
                return end

                --> Look at Target
                local rig_model = self.rig.model
                if not rig_model or not rig_model.PrimaryPart then
                    warn(`[{script.Name}] Unsure what happened, model despawned & state stayed observing! Falling back into idle.`)
                    self.fsm:switchState('idle')
                    return
                end

                local surface_normal = (env.shared.observe_position :: {Vector3})[2] 
                local rig_position = (env.shared.observe_position :: {Vector3})[1] or self.rig.model.PrimaryPart.Position
                
                local observe_cf = observe_target.PrimaryPart.CFrame
                local observe_position = observe_cf.Position

                local look_cf = CFrame.lookAt(
                    rig_position, 
                    Vector3.new(observe_position.X, rig_position.Y, observe_position.Z)
                )

                local fixed_cf: CFrame = look_cf
                    +(surface_normal*rig_model.PrimaryPart.Size.Z)
                    -look_cf.upVector*(rig_model['Left Leg'].Size.Y+rig_model.PrimaryPart.Size.Y/2)
                self.rig.model.PrimaryPart.CFrame = fixed_cf

                --> Wait until disappear (w/ patience parameter)
                local this_tick = tick()
                -- if not env.is_evading then
                --     if this_tick-env.started_observing>=(10*patience) then
                --         env.shared.learn:process('observation_completed')

                --         self.fsm:switchState('idle')
                --         print(`[{script.Name}] Completed my observation! Going back into hiding...`)

                --         return
                --     end
                -- end

                --> Check for Evasion
                local fixed_position = fixed_cf.Position + fixed_cf.LookVector*2

                if (this_tick-env.watch_cast_tick) > (30/60) then
                    env.watch_cast_tick = this_tick

                    --]] New Look Casts

                    --> Get player's left & right
                    local left_p = observe_position - observe_cf.rightVector*2
                    local right_p = observe_position + observe_cf.rightVector*2

                    --> Create CFrames looking from the entity to those points
                    local left = CFrame.lookAt(fixed_position, left_p)
                    local right = CFrame.lookAt(fixed_position, right_p)
                    local left_mag, right_mag = (fixed_position-left_p).Magnitude, (fixed_position-right_p).Magnitude

                    --> Raycast left & right
                    local cast_left = workspace:Raycast(fixed_position, left.LookVector*left_mag, env.watch_cast_info)
                    local cast_right = workspace:Raycast(fixed_position, right.LookVector*right_mag, env.watch_cast_info)

                    --> Debug
                    if DEBUG_SIGHT_RAYS then
                        local sight_left = Instance.new('Part')
                        sight_left.Anchored, sight_left.CanCollide = true, false
                        sight_left.Material, sight_left.Color = Enum.Material.Neon, cast_left==nil and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                        sight_left.Transparency = .75

                        local sight_right = Instance.new('Part')
                        sight_right.Anchored, sight_right.CanCollide = true, false
                        sight_right.Material, sight_right.Color = Enum.Material.Neon, cast_right==nil and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                        sight_right.Transparency = .75

                        sight_left.CFrame = CFrame.lookAt(fixed_position:Lerp(left_p, .5), left_p)
                        sight_right.CFrame = CFrame.lookAt(fixed_position:Lerp(right_p, .5), right_p)

                        sight_left.Size = Vector3.new(.1, .1, left_mag)
                        sight_right.Size = Vector3.new(.1, .1, right_mag)

                        sight_left.Name, sight_right.Name = 'sight_left', 'sight_right'
                        sight_left.Parent, sight_right.Parent = workspace.Terrain, workspace.Terrain

                        Debris:AddItem(sight_left, 1)
                        Debris:AddItem(sight_right, 1)
                    end

                    env.is_evading = cast_left and cast_right
                    if env.is_evading then
                        local max_ticks = math.ceil(patience*20)

                        env.ticks_evaded += 1
                    
                        if (env.ticks_evaded :: number)>=max_ticks then
                            print(`[{script.Name}] Player evaded me! Going back into hiding...`)
                            env.shared.learn:process('player_evasion')
                            self.fsm:switchState('idle')

                            return
                        else
                            print(`[{script.Name}] Losing track of player! Evaded for {env.ticks_evaded} / {max_ticks} ticks...`)
                        end
                    end
                end

                --> Increase pressure
                --// TODO: This whole thing needs to be fixed, my idea is:
                --// 1. Broadcast to the player when they are chosen
                --// 2. On the client, when this entity first idles, initalize a router.
                --// 3. Check 30?fps if looking at the entity, send an event if so.
                --// 4. On the server, if the pressure exceeds, then do this.
                local look_direction_object: Vector3, yaw: number = unpack(env.shared.senses.player:getPlayerLookDirection(env.shared.observe_target_p))
                yaw = (yaw+math.pi)%(2*math.pi)-math.pi

                -- print("Object space camera direction:", look_direction_object)
                -- print("Body yaw:", yaw)

                local body_rotation = CFrame.Angles(0, yaw, 0)

                local player_root = env.shared.observe_target.PrimaryPart
                local oriented_cf = player_root.CFrame * body_rotation

                local look_direction = oriented_cf:VectorToWorldSpace(look_direction_object).Unit
                
                local distance = (fixed_position-observe_cf.Position).Magnitude

                local player_to_entity = (fixed_position - observe_cf.Position).Unit
                local is_looking = look_direction:Dot(player_to_entity) > .5
                -- print("===")
                -- print("Look direction (world):", look_direction)
                -- print("Player to entity:", player_to_entity)
                -- print("Dot:", look_direction:Dot(player_to_entity))

                if is_looking and env.is_evading then
                    env.shared.pressure=math.min(env.shared.pressure+patience*(75/distance), 200)
                    -- print(`Pressure: +{patience*(75/distance)}, ({env.shared.pressure})`)
                else
                    env.shared.pressure=math.max(env.shared.pressure-patience*(50/distance), 0)
                    -- print(`Calm: -{patience*(50/distance)}, ({env.shared.pressure})`)
                end

                local maximum_pressure = patience*100
                local exceeded_pressure = env.shared.pressure :: number >= maximum_pressure

                --> Despawn
                if exceeded_pressure then
                    env.shared.learn:process('spotted')

                    self.fsm:switchState('idle')
                    print(`[{script.Name}] Eye Contact pressure exceeded! Going back into hiding...`)

                end

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

Watcher.data = {
}

return Watcher