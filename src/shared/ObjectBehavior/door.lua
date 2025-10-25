--[[

    Door Object Behavior

    Griffin Dalby
    2025.10.25

    This module will provide behavior for the "Door" object, usable for
    both server & client.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')
local debris = game:GetService('Debris')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local map_cache = cache.findCache('map')
local door_cache = map_cache:createTable('doors', true)

--]] Settings
local debug_rays = false

--]] Constants
--]] Variables
--]] Functions
function visualizeRay(a: Vector3, b: Vector3, success: boolean)
    local ray = Instance.new('Part'); debris:AddItem(ray, 3.5)
    ray.Anchored, ray.CanCollide = true, false
    ray.Color, ray.Material = (success and Color3.new(0,1,0) or Color3.new(1,0,0)), Enum.Material.Neon
    ray.Transparency = .5

    local base = a:Lerp(b,.5)
    local mag = (a-b).Magnitude

    ray.CFrame = CFrame.lookAt(base, b)
    ray.Size = Vector3.new(.1, .1, mag)
    ray.Parent = workspace.Terrain

    return ray
end

function labelRay(ray: Part, content: string)
    local board = Instance.new('BillboardGui')
    local label = Instance.new('TextLabel')

    board.LightInfluence = 0
    board.Size = UDim2.new(4, 0, .85, 0)
    board.AlwaysOnTop = true

    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true

    label.RichText = true
    label.Text = content

    board.Parent = ray
    label.Parent = board
end

function truncateNumber(number: number)
    return math.floor(number*(10^2))/(10^2) end

--]] Behavior
local door = {}
door.__index = door

type self = {
    model: Model,
    hinge: HingeConstraint,

    is_open: boolean,
}
export type Door = typeof(setmetatable({} :: self, door))

function door.new(door_model: Model) : Door
    local self = setmetatable({} :: self, door)

    self.model = door_model
    self.hinge = door_model.PrimaryPart:FindFirstChildWhichIsA('HingeConstraint')

    self.is_open = false

    door_cache:setValue(door_model, self)
    return self
end

function door:open(player: Player)
    self.is_open = true
    local door_primary = self.model.PrimaryPart :: Part

    --> Raycast for Normal
    local character = player.Character
    local root_part = character.PrimaryPart :: Part
    
    local cast_params = RaycastParams.new()
    cast_params.CollisionGroup = 'Door'
    cast_params.FilterDescendantsInstances = {self.model}
    cast_params.FilterType = Enum.RaycastFilterType.Include
    
    local v3 = (door_primary.Position-root_part.Position)
    local mag, unit = v3.Magnitude, v3.Unit

    local cast = workspace:Raycast(root_part.Position, unit*(mag*1.1), cast_params) :: RaycastResult
    local cast_debug_ray = if debug_rays then visualizeRay(door_primary.Position, root_part.Position, cast~=nil) else nil
    if not cast then
        warn(`[{script.Name}] Cast to open door intercepted nothing! Player not close enough.`)
        return end
    
    --> Open Door
    local dot_product = door_primary.CFrame.LookVector:Dot(cast.Normal)
    self.hinge.TargetAngle = self.hinge.UpperAngle*-dot_product

    door_primary.CollisionGroup = 'MovingDoor'
    door_primary.CanCollide = false
    task.delay(.5, function()
        door_primary.CollisionGroup = 'Door'
        door_primary.CanCollide = true end)
    
    if cast_debug_ray then
        labelRay(cast_debug_ray,
            `{truncateNumber(cast.Normal.X)}, {truncateNumber(cast.Normal.Y)}, {truncateNumber(cast.Normal.Z)} (Dot: {dot_product})`)
    end
end

function door:close()
    local door_primary = self.model.PrimaryPart :: Part

    self.is_open = false
    self.hinge.TargetAngle = 0

    door.CollisionGroup = 'MovingDoor'
    door_primary.CanCollide = false
    task.delay(.5, function()
        door.CollisionGroup = 'Door'
        door_primary.CanCollide = true end)
end

return door