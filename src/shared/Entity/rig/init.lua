--[[

    Entity Rig

    Griffin Dalby
    2025.09.16

    This module will provide a object that holds & handles the entities
    rig.

--]]

--]] Services
local runService = game:GetService('RunService')

--]] Modules
local types = require(script.Parent.types)
local animator = require(script.animator)

--]] Sawdust
--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Rig
local rig = {} :: types.methods_rig
rig.__index = rig

--[[
    Constructor function for a rig object, which will take in a couple
    of physical values to generate a rig controller
    
    @param rig_data Data to setup Rig object

    @return EntityRig
]]
function rig.new(rig_data: types.RigData) : types.EntityRig
    local self = setmetatable({} :: types.self_rig, rig)

    --] Sanitize
    assert(rig_data.model, `Missing "model" in RigData!`)
    assert(rig_data.spawns, `Missing "spawns" in RigData!`)

    assert(typeof(rig_data.model)=='Instance' and rig_data.model:IsA('Model'),
        `"model" in RigData isn't a model!`)
    assert(type(rig_data.spawns)=='table',
        `"spawns" in RigData was passed as a {type(rig_data.spawns)}, it was expected to be a table. (\{[BasePart]})`)

    --] Initalize
    if not workspace.environment:FindFirstChild('entities') then
        Instance.new('Folder', workspace.environment).Name = 'entities'; end

    self.model = rig_data.model:Clone()
    self.model.Name = rig_data.id or self.model.Name
    self.model.Parent = script

    self.spawns = rig_data.spawns
    self.animator = animator.new()

    return self
end

--[[
    This will spawn this rig into the physical world at either the
    specified spawn_part or a random spawn point 
    
    @param spawn_point Part or Vector3 of spawn point
]]
function rig:spawn(spawn_point: BasePart | Vector3)
    assert(not is_client, `Cannot :spawn() rig on the client-side!`)

    local function doSpawn(part: BasePart|Vector3)
        local half_vert = self.model:GetBoundingBox().Y/2
        local spawn = (typeof(part)=='Instance' and part.Position or (part :: Vector3))--+Vector3.new(0,half_vert,0)

        self.model.PrimaryPart.CFrame = CFrame.new(spawn)
        self.model.Parent = workspace.environment.entities

        self.model.PrimaryPart:SetNetworkOwner(nil)
    end

    if spawn_point then --> Spawn @ specifed spawn.
        doSpawn(spawn_point)
    else --> Spawn @ random spawn.
        local random_id = math.random(1, #self.spawns)
        local selected = self.spawns[random_id]

        doSpawn(selected)
    end
end

--[[
    This will despawn this rig from the physical world.
]]
function rig:despawn()
    assert(not is_client, `Cannot :despawn() rig on the server-side!`)
    assert(self.model, `Cannot :despawn() while already despawned!`)

    self.model.Parent = script
end

return rig