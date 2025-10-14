--[[

    Item Prop Generator.

    Griffin Dalby
    2025.10.13

    This script will generate items from the props folder

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local Iitem = require(replicatedStorage.Shared.Item)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Script
for _, object: Model|BasePart in pairs(workspace.item_props:GetChildren()) do
    local object_id = object:GetAttribute('item_id')
    local new_item  = Iitem.new(object_id)
    new_item:setTransform(object.CFrame)

    object:Destroy()
end
workspace.item_props:Destroy()