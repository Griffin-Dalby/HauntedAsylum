--!strict
--[[

    Hiding Event Endpoints

    Griffin Dalby
    2025.10.17

    This script provides endpoints for hiding in things.

--]]

--]] Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Https = game:GetService("HttpService")
local RunService = game:GetService("RunService")

--]] Modules
--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)

local Networking = Sawdust.core.networking
local Cache = Sawdust.core.cache

--> Networking
local mechanics = Networking.getChannel('mechanics')

--> Cache
local players_cache = Cache.findCache('players')
local session_cache = players_cache:createTable('session', true)

--]] Settings
local crouch_spots = {
    workspace.environment.hiding_desks
} :: {
    Folder & {
        Model & {
            BasePart
        }
    }
}

--]] Constants
--]] Variables
--]] Functions
function pTag(p: Player)
    return `{p.Name}#{p.UserId}` end

--]] Cache Crouch Hide Spots
local crouch_hide_spots = {} :: {
    [string]: { Model | BasePart }
}

print(`[{script.Name}-CSC] Caching crouch spots...`)

local cache_count = 0
for _, model_folder: Folder in pairs(crouch_spots) do
    for _, model in pairs(model_folder:GetChildren()) do
        if not model:IsA('Model') then continue end

        --> Save ID
        cache_count += 1
        local model_hide_id = Https:GenerateGUID(false)
        model:SetAttribute("hide_id", model_hide_id)

        --> Get hide spot
        local hide_spot = model:FindFirstChild('Hide') :: BasePart
        if not hide_spot then
            warn(`[{script.Name}] Spot @ "{model:GetFullName()}" does not have a Hide Spot!`)
            continue
        end

        --> Save to 
        crouch_hide_spots[model_hide_id] = {model, hide_spot}
    end
end

print(`[{script.Name}-CSC] Cached {cache_count} spots!`)

--]] Script
mechanics.hiding:route()
    :on('exit_locker', function(req, res)
        local player = req.caller

        local session_data = session_cache:getValue(req.caller)
        local is_hiding = session_data.is_hiding
        if not is_hiding then
            res.reject()
            error(`[{script.Name}] Player "{pTag(player)}" is already hiding!`)
        end

        local character = player.Character
        local humanoid  = character.Humanoid
        local root_part = humanoid.RootPart

        local locker_model = is_hiding[1].Parent.Parent :: Model & {
            Door: Model & {
                Body: BasePart
            }
        }
        local body = locker_model['Door']['Body'] :: Part

        task.delay(1, function()
            body:SetNetworkOwner(nil)
        end)
        root_part.Anchored = false
        -- root_part.CFrame = is_hiding[2]

        session_data.is_hiding = false
    end)

    :on('crouch_hide', function(req, res)
        local player = req.caller

        --> Sanitize Input
        local hide_model_id = req.data[1]
        local hide_model_data = crouch_hide_spots[hide_model_id]
        if not res.assert((hide_model_data~=nil), 
            "invalid_id") then return end
        
        local hide_model, hide_part = 
            hide_model_data[1] :: Model, 
            hide_model_data[2] :: BasePart

        --> Get SessionData
        local session_data = session_cache:getValue(player)
        local is_hiding    = session_data.is_hiding :: boolean
        if not res.assert(is_hiding==false, 
            "invalid_state") then return end

        --> Get Character
        local character = player.Character
        local humanoid  = character:FindFirstChildWhichIsA("Humanoid")
        local root_part = humanoid.RootPart

        --> Check Perimeter
        local function CheckInHidingSpot() : boolean
            --> Extract Pos & Size
            local root_p, hide_p = root_part.Position, hide_part.Position
            local root_s, hide_s = root_part.Size, hide_part.Size

            local padding = Vector3.new( .1, 0, .1 )

            --> Check Positions
            local x_valid = ((root_p.X+root_s.X/2) + padding.X) <= (hide_p.X+hide_s.X/2) 
                        and ((root_p.X-root_s.X/2) + padding.X) >= (hide_p.X-hide_s.X/2)

            -- local y_valid = (root_p.Y+root_s.Y/2) <= (hide_p.Y+hide_s.Y/2)
            --             and (root_p.Y-root_s.Y/2) >= (hide_p.Y-hide_s.Y/2)

            local z_valid = ((root_p.Z+root_s.Z/2) + padding.Z) <= (hide_p.Z+hide_s.Z/2)
                        and ((root_p.Z-root_s.Z/2) + padding.Z) >= (hide_p.Z-hide_s.Z/2)

            return x_valid and z_valid
        end
        if not res.assert(CheckInHidingSpot()==true, 
            "invalid_position") then return end

        print(`[{script.Name}] Player "{pTag(player)}" entered their hiding spot!`)

        --> Start Hiding
        session_data.is_hiding = true
        
        local hide_promise: RBXScriptConnection?
        hide_promise = RunService.Heartbeat:Connect(function() 
            local in_spot = CheckInHidingSpot()
            if not in_spot then
                print(`[{script.Name}] Player "{pTag(player)}" left their hiding spot!`)
                session_data.is_hiding = false

                if hide_promise then
                    hide_promise:Disconnect()
                    hide_promise = nil
                else
                    warn(`[{script.Name}] hide_promise MemLeak detected!`)
                end
            end
        end)

        res.data()
        res.send()

    end)
 