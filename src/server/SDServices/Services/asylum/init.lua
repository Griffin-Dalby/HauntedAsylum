--[[

    Asylum SDService

    Griffin Dalby
    2025.11.19

    This module will provide a SDService while will control the Asylum;
    it's behavior, timings, and other things like tracking which 
    room / floor any given player is on.

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--]] Modules
--]] Sawdust
local sawdust = require(ReplicatedStorage.Sawdust)

local builder = sawdust.builder

--]] Settings
local KEY_FORMAT_FLOOR_FOLDER = "%s-%s"
local KEY_FORMAT_FLOOR_FOLDER_ROOM = "%s-%s#%s"
local KEY_FORMAT_FLOOR_ROOM = "%s-%s"

--]] Constants
local asymap = workspace:WaitForChild("asylum.map")

--]] Variables
--]] Functions
--> Mappings Generator
local function GenerateMappings() : {[string]: Part|Folder}
    local mappings: {[string]: Part|Folder} = {}
    local floor_sorted: {[number]: {[string]: {connections: {Part|Folder}, room: Part|Folder}}} = {}

    --> Create Mappings
    for _, floor: Part in asymap:GetChildren() do
        if not floor:IsA("Part") then continue end

        local split = floor.Name:split('_')
        if #split < 2 then 
            warn(`Floor {floor.Name} has invalid name format, expected '$prefix_$id'`)
            continue end

        local id = tonumber(split[2]) or 1

        floor_sorted[id] = {}
        local floor_tbl = floor_sorted[id]

        mappings[tostring(id)] = floor
        for _, child: Instance in floor:GetChildren() do
            local child_name = child.Name

            if child:IsA('Folder') then
                local f_key = (KEY_FORMAT_FLOOR_FOLDER):format(id, child_name)
                assert(not mappings[f_key], `Collision detected while mapping asylum! (F-F "{f_key}" already exists)`)

                mappings[f_key] = child
                floor_tbl[child_name] = {connections = {}}

                for _, part: Instance in child:GetChildren() do
                    if not part:IsA('Part') then continue end

                    --> Generate Mapping
                    local part_name = part.Name
                    local key = (KEY_FORMAT_FLOOR_FOLDER_ROOM):format(id, child_name, part_name)
                    assert(not mappings[key], `Collision detected while mapping asylum! (F-F-R "{key}" already exists)`)
                    mappings[key] = part

                    --> Get Connections
                    local room_connections_raw = part:FindFirstChild("connections")
                    local room_connections = if room_connections_raw~=nil then {} else nil
                    if room_connections_raw then
                        for _, connection_p in pairs(room_connections_raw:GetChildren()) do
                            if not connection_p:IsA("BasePart") then continue end

                            room_connections[connection_p.Name] = connection_p.Position
                            floor_tbl[child_name].connections[connection_p.Name] = connection_p.Position
                        end
                    end
                    
                    floor_tbl[child_name][part_name] = {connections = room_connections, room = part}
                end
            elseif child:IsA('Part') then
                local key = (KEY_FORMAT_FLOOR_ROOM):format(id, child_name)
                assert(not mappings[key], `Collision detected while mapping asylum! (F-R "{key}" already exists)`)

                mappings[key] = child
                floor_tbl[child_name] = {connections = {}, room = child}
            end
        end
    end

    return mappings, floor_sorted
end

--]] Service
type self = {
    --]] Properties
    mappings: {[string]: Part|Folder},
    mappings_sorted: {[number]: {[string]: {
        connections: {[string]: Vector3}?,
        room: Instance
    }}},
    
    --> Signals
    room_entered: sawdust.SawdustSignal<Player, string>,
    room_exited: sawdust.SawdustSignal<Player, string>,

    floor_entered: sawdust.SawdustSignal<Player, string>,
    floor_exited: sawdust.SawdustSignal<Player, string>,

    --> Stats
    room_stats: {
        [string]: {
            players: {[Player]: number}, --> number is the timestamp they entered room
            activity: {[number]: string} --> number is the timestamp of activity, string is the ID.
        }
    },

    player_stats: {
        [Player]: {
            current_room: string,
            current_floor: string,
        }
    },

    --]] Methods
    Fetch: (id: string) -> (Part|Folder)?,
    GetFloor: (floor_id: number) -> Part?,
    GetRoom: (floor_id: number, room_id: string, section_id: string?) -> Part?,

    GetConnectedRooms: (floor_id: number, room_id: string, section_id: string?) -> { [string]: Vector3 },

    PlayerEnteredRoom: (player: Player, room_id: string) -> nil,
    PlayerExitedRoom: (player: Player, room_id: string) -> nil,
}

return builder.new('asylum')
    :init(function(self, deps)
        local mappings, sorted_mappings = GenerateMappings()
        self.mappings = mappings
        self.mappings_sorted = sorted_mappings --> Make accessors

        --> Create Signals
        local signal_emitter = sawdust.core.signal.new()
        self.room_entered = signal_emitter:newSignal()
        self.room_exited = signal_emitter:newSignal()

        self.floor_entered = signal_emitter:newSignal()
        self.floor_exited = signal_emitter:newSignal()

        --> Populate Room Stats
        self.room_stats = {}
        self.player_stats = {}

        for mapping_id, mapping_part in pairs(mappings) do
            if string.match(mapping_part.Name, "#")~=nil then continue end --> Don't map folder sectors
            self.room_stats[mapping_id] = {
                players = {},  --> Players currently in room
                activity = {}, --> Timestamped activity within room
            }
        end
    end)

    --> Room/Floor Fetch
    :method('Fetch', function(self: self, id: string): (Part|Folder)?
        return self.mappings[id] end)
    :method('GetFloor', function(self: self, floor_id: number): Part?
        return self.Fetch(tostring(floor_id)) :: Part? end)
    :method('GetRoom', function(self: self, floor_id: number, room_id: string, section_id: string?): (Part|Folder)?
        local key = section_id 
            and (KEY_FORMAT_FLOOR_FOLDER_ROOM):format(floor_id, room_id, section_id) 
            or  (KEY_FORMAT_FLOOR_ROOM):format(floor_id, room_id)

        return self.Fetch(key) end)

    --> Connections
    :method('GetConnectedRooms', function(self: self, floor_id: number, room_id: string, section_id: string?)
        print(self.mappings_sorted, `{floor_id}: {type(floor_id)}`, `{room_id}: {type(room_id)}`)
        local room_data = self.mappings_sorted[tonumber(floor_id) or 1][room_id]
        
        --> Fetch Connections
        local connections: typeof(room_data.connections) = 
            if section_id then (room_data[section_id] and room_data[section_id] or room_data).connections
                          else room_data.connections
        
        --> 
        return connections
    end)

    --> Player Tracking
    :method('PlayerEnteredRoom', function(self: self, player: Player, room_id: string)
        local this_room_stats = self.room_stats[room_id]
        local this_tick = tick()

        if this_room_stats then
            this_room_stats.players[player] = this_tick
            this_room_stats.activity[this_tick] = `PlayerEntered-{player.UserId}`
        else
            error(`[{script.Name}] Failed to fetch RoomStats for room w/ ID "{room_id or "<None Provided>"}"!`)
        end
    end)
    :method('PlayerExitedRoom', function(self: self, player: Player, room_id: string)
        local this_room_stats = self.room_stats[room_id]
        local this_tick = tick()

        if this_room_stats then
            this_room_stats.players[player] = nil
            this_room_stats.activity[this_tick] = `PlayerExited-{player.UserId}`
        else
            error(`[{script.Name}] Failed to fetch RoomStats for room w/ ID "{room_id or "<None Provided>"}"!`)
        end
    end)

    :start(function(self: self)
        print("Starting Asylum...")
        local last_update = tick()

        local function CheckInBounds(player: Player, bounds: Part|Folder)
            local plr_position = player.Character 
                    and player.Character.PrimaryPart 
                    and player.Character.PrimaryPart.Position
                
            local function check(origin_position: Vector3, box_size: Vector3)
                return 
                    (plr_position.X < origin_position.X+box_size.X/2 and plr_position.X>origin_position.X-box_size.X/2)
                and (plr_position.Y < origin_position.Y+box_size.Y/2 and plr_position.Y>origin_position.Y-box_size.Y/2)
                and (plr_position.Z < origin_position.Z+box_size.Z/2 and plr_position.Z>origin_position.Z-box_size.Z/2)
            end
            if bounds:IsA('Folder') then
                for _, bounds_part in pairs(bounds:GetChildren()) do
                    if not bounds_part:IsA('BasePart') then continue end
                    if check(bounds_part.Position, bounds_part.Size) then
                        return true
                    end
                end

                return false
            else
                return check(bounds.Position, bounds.Size)
            end
        end

        local runtime = RunService.Heartbeat:Connect(function(dT)
            --> Tick Limiter
            local this_tick = tick()
            local difference = this_tick-last_update

            if difference<30/60 then --> 30fps update
                return end
            last_update = this_tick

            --> Iterate Rooms
            for area_id: string, area_bounds: Part|Folder in pairs(self.mappings) do
                local is_floor = (tonumber(area_id)~=nil) and true or false
                
                coroutine.wrap(function()

                    for _, player: Player in ipairs(Players:GetPlayers()) do
                        
                        local in_bounds = CheckInBounds(player, area_bounds)

                        --> Generate Player Stats
                        if not self.player_stats[player] then
                            self.player_stats[player] = {
                                current_floor = '1',
                                current_room = '1-main_L#main'
                            }
                        end

                        --> Compare Player Stats
                        if not in_bounds then return end
                        if is_floor then

                            local last_floor = self.player_stats[player].current_floor
                            if last_floor~=area_id then
                                --> Send Updates
                                self.floor_entered:fire(player, area_id)
                                self.floor_exited:fire(player, last_floor)

                                self.PlayerEnteredRoom(player, area_id)
                                self.PlayerExitedRoom(player, last_floor)

                                --> Update Current Floor
                                self.player_stats[player].current_floor = area_id
                            
                                -- print(`Exited Floor:  {last_floor}`)
                                print(`Entered Floor: {area_id}\n`)
                            end

                        else

                            local is_hash = string.match(area_id, "#")
                            if is_hash~=nil then continue end --> Only use folders

                            local last_room = self.player_stats[player].current_room
                            if last_room~=area_id then
                                --> Send Updates
                                self.room_entered:fire(player, area_id)
                                self.room_exited:fire(player, last_room)

                                self.PlayerEnteredRoom(player, area_id)
                                self.PlayerExitedRoom(player, last_room)

                                --> Update Current Room
                                self.player_stats[player].current_room = area_id

                                -- print(`Exited Room:  {last_room}`)
                                print(`Entered Room: {area_id}\n`)
                            end

                        end

                    end

                end)()
            end
        end)

        print("Asylum Started!!")
    end)
