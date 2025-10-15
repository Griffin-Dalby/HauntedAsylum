--[[

    Item Prop Generator.

    Griffin Dalby
    2025.10.13

    This script will generate items from the props folder

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local players = game:GetService('Players')

--]] Modules
local Iitem = require(replicatedStorage.Shared.Item)
local Titem = require(replicatedStorage.Shared.Item.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local world = networking.getChannel('world')

--> Cache
local item_cache = cache.findCache('items')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
for _, object: Model|BasePart in pairs(workspace.item_props:GetChildren()) do
    local object_id = object:GetAttribute('item_id')
    local new_item  = Iitem.new(object_id)
    new_item:setTransform(object.CFrame, false)

    object:Destroy()
end
workspace.item_props:Destroy()

function broadcastObjects(player: Player)
    for _, item: Titem.Item in pairs(item_cache:getContents()) do
        world.item:with()
            :broadcastTo(player)
            :intent('instantiate')
            :data(item.id, item.uuid, item.model.transform)
            :fire()
    end
end

players.PlayerAdded:Connect(broadcastObjects)
for _, player in pairs(players:GetPlayers()) do
    broadcastObjects(player) end