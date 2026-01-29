--[[

    Entity Asylum Sense

    Griffin Dalby
    2026.1.28

        This module provides asylum senses for entities, giving them
    knowledge of each room, players in each room, and recent activity.
    
    This "guides" the entity around the asylum smarter, allowing them
    to follow smartly.

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")

--]] Modules
local Types = require(script.Parent.types)

--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)
local SawSvc = Sawdust.services

--]] Settings
--]] Constants
local is_client = RunService:IsClient()

--]] Variables
--]] Functions
--]] Module

return function(cortex: Types.EntityCortex)
    local sense = {} :: Types.self_sense_asylum
    setmetatable(sense, {__index = sense} :: Types.methods_sense_asylum)

    local settings = cortex.__settings.asylum

    if is_client then
        return sense
    end

    --> Asylum Mapping
    local timeout = false
    task.delay(7.5, function()
        timeout = true
    end)
    repeat task.wait(.1) until timeout or
        SawSvc._registry['asylum']
    and SawSvc._instances['asylum']
    and SawSvc._states['asylum'] == 'started'

    if timeout then
        error(`[{script.Name}] Timeout exceeded, waiting for asylum service to start!`)
    end


    local AsySvc = SawSvc:getService("asylum")
    sense.mapping = AsySvc.mappings_sorted :: typeof(sense.mapping)
    
    function sense:Fetch(id: string)
        return AsySvc.Fetch(id) end
    function sense:GetFloor(floor_id: number)
        return AsySvc.GetFloor(floor_id) end
    function sense:GetRoom(floor_id: number, room_id: string, section_id: string?)
        return AsySvc.GetRoom(floor_id, room_id, section_id) end

    function sense:GetConnectedRooms(floor_id: number, room_id: string, section_id: string?)
        return AsySvc.GetConnectedRooms(floor_id, room_id, section_id) end
    function sense:GetSortedMappings()
        return AsySvc.mappings_sorted end
    
    return sense
end