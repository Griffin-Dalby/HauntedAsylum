--[[

    Entity Rig

    Griffin Dalby
    2025.09.16

    This module will provide a object that holds & handles the entities
    rig.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.types)
local animator = require(script.animator)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Rig
local rig = {}
rig.__index = rig

--[[ rig.new(rig_dataL RigData) : EntityRig
    Constructor function for a rig object, which will take in a couple
    of physical values to generate a rig controller ]]
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

    self.model = rig_data.model
    self.model.Name = rig_data.id or self.model.Name

    self.spawns = rig_data.spawns
    self.animator = animator.new()

    return self
end

--[[ rig:spawn(spawn_part: BasePart?)
    This will spawn this rig into the physical world at either the
    specified spawn_part or a random spawn point ]]
function rig:spawn(spawn_part: BasePart?)
    local function doSpawn(part: BasePart)
        local half_vert = self.model:GetBoundingBox().Y/2
        local spawn = part.Position+Vector3.new(0,half_vert,0)

        self.model.PrimaryPart.CFrame = CFrame.new(spawn)
        self.model.Parent = workspace.environment.entities
    end

    if spawn_part then --> Spawn @ specifed spawn.
        doSpawn(spawn_part)
    else --> Spawn @ random spawn.
        local random_id = math.random(1, #self.spawns)
        local selected = self.spawns[random_id]

        doSpawn(selected)
    end
end

return rig