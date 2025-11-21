--[[

<<<<<<< HEAD
    Asylum SDService

    Griffin Dalby
    2025.11.19

    This module will provide a SDService while will control the Asylum;
    it's behavior, timings, and other things like tracking which 
    room / floor any given player is on.
=======
    Asylum Service

    Griffin Dalby
    2025.11.17

    This service will manage player asylum data, mapping zones to the asylum.
>>>>>>> 55088a78bea3eacf424e9ae1b0d253b5e14779e1

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--]] Modules
--]] Sawdust
local sawdust = require(ReplicatedStorage.Sawdust)

local builder = sawdust.builder

--]] Settings
local KEY_FORMAT_FLOOR_FOLDER = "%s-%s"
local KEY_FORMAT_FLOOR_FOLDER_ROOM = "%s-%s#%s"
local KEY_FORMAT_FLOOR_ROOM = "%s-%s"

--]] Constants
local asymap = ServerStorage:WaitForChild("asylum.map")

--]] Variables
--]] Functions
local function generateMappings() : {[string]: Part|Folder}
    local mappings: {[string]: Part|Folder} = {}

    for _, floor: Part in asymap:GetChildren() do
        if not floor:IsA("Part") then continue end

        local split = floor.Name:split('_')
        if #split < 2 then 
            warn(("Floor %s has invalid name format, expected '$prefix_$id'"):format(floor.Name))
            continue end

        local id: string = tostring(split[2])
        mappings[id] = floor
        for _, child: Instance in floor:GetChildren() do
            if child:IsA('Folder') then
                local f_key = (KEY_FORMAT_FLOOR_FOLDER):format(id, child.Name)
                assert(not mappings[f_key], `Collision detected while mapping asylum! (F-F "{f_key}" already exists)`)

                mappings[f_key] = child

                for _, part: Instance in child:GetChildren() do
                    if not part:IsA('Part') then continue end

                    local key = (KEY_FORMAT_FLOOR_FOLDER_ROOM):format(id, child.Name, part.Name)
                    assert(not mappings[key], `Collision detected while mapping asylum! (F-F-R "{key}" already exists)`)
                    mappings[key] = part
                end
            elseif child:IsA('Part') then
                local key = (KEY_FORMAT_FLOOR_ROOM):format(id, child.Name)
                assert(not mappings[key], `Collision detected while mapping asylum! (F-R "{key}" already exists)`)

                mappings[key] = child
            end
        end
    end

    return mappings
end

--]] Service
return builder.new('asylum')
    :init(function(self, deps)
        self.mappings = generateMappings()
    end)

    :method('fetch', function(self, id: string): (Part|Folder)?
        return self.mappings[id] end)
    :method('getFloor', function(self, floorId: number): Part?
        return self:fetch(tostring(floorId)) end)
    :method('getRoom', function(self, floorId: number, roomId: string, specify: string?): Part?
        local key = specify and (KEY_FORMAT_FLOOR_FOLDER_ROOM):format(floorId, roomId, specify) or (KEY_FORMAT_FLOOR_ROOM):format(floorId, roomId)
        return self:fetch(key) end)

    :start(function(self)
        
    end)
