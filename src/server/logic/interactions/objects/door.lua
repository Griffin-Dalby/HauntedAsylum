--[[

    Example Object & Prompt Decleration (SERVER)

    Griffin Dalby
    2025.09.10

    This module will provide example data for object & prompt
    registration on the server side.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local debris = game:GetService('Debris')

--]] Modules
local interactable = require(replicatedStorage.Shared.Interactable)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache

--> Cache
local map_cache = cache.findCache('map')
local door_cache = map_cache:createTable('doors')

--]] Settings
local debug_rays = true

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

--]] Door Object

local doors_open = {}

return function ()
    local door_object = interactable.newObject{
        object_id = 'door',
        object_name = 'Door',

        instance = {workspace.doors, {}},
        prompt_defs = {
            range = 10
        }
    }

    local door_interact = door_object:newPrompt{
        prompt_id = 'interact',
        action = 'Interact',
        cooldown = .5,
    }
    door_interact.triggered:connect(function(self, door: Part, player: Player)
        local hinge = door:FindFirstChildWhichIsA('HingeConstraint')

        --> Cache
        local door_data
        if door_cache:hasEntry(door) then
            door_data = door_cache:findTable(door)
        else
            door_data = door_cache:createTable(door)
            door_data:setValue('open', false)
        end

        local function close_door()
            door_data:setValue('open', false)
            hinge.TargetAngle = 0
        end

        local function open_door()
            door_data:setValue('open', true)

            --> Raycast for Normal
            local character = player.Character
            local root_part = character.PrimaryPart :: Part
            
            local cast_params = RaycastParams.new()
            cast_params.FilterDescendantsInstances = {door.Parent}
            cast_params.FilterType = Enum.RaycastFilterType.Include
            
            local v3 = (door.Position-root_part.Position)
            local mag, unit = v3.Magnitude, v3.Unit

            local cast = workspace:Raycast(root_part.Position, unit*(mag*1.1), cast_params) :: RaycastResult
            local cast_debug_ray = if debug_rays then visualizeRay(door.Position, root_part.Position, cast~=nil) else nil
            if not cast then
                warn(`[{script.Name}] Cast to open door intercepted nothing! Player not close enough.`)
                return end
            
            --> Open Door
            local dot_product = door.CFrame.LookVector:Dot(cast.Normal)
            hinge.TargetAngle = hinge.UpperAngle*-dot_product
            
            if cast_debug_ray then
                labelRay(cast_debug_ray,
                    `{truncateNumber(cast.Normal.X)}, {truncateNumber(cast.Normal.Y)}, {truncateNumber(cast.Normal.Z)} (Dot: {dot_product})`)
            end
        end

        if door_data:getValue('open') then
            close_door()
        else
            open_door()
        end
        
    end)

    return door_object
end