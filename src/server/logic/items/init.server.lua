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
    local sorted_items = {}
    for _, item: Titem.Item in pairs(item_cache:getContents()) do
        if not sorted_items[item.id] then
            sorted_items[item.id]={} end
        table.insert(sorted_items[item.id], item.model.instance)

        world.item:with()
            :broadcastTo(player)
            :intent('instantiate')
            :data(item.id, item.uuid, item.model.transform)
            :fire()
    end

    --]] Broadcast Prompts
    for object_id: string, objects: {Instance} in pairs(sorted_items) do
        world.interaction:with()
            :broadcastTo(player)
            :intent('attach_instances')
            :data(object_id, 'pickup', objects)
            :fire()
    end
end

world.interaction:route()
    :on('ready', function(req, res)
        broadcastObjects(req.caller)
    end)