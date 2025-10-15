--[[

    Item Factory Object

    Griffin Dalby
    2025.09.17

    This module provides base item object logic, which can be expanded with
    additional features via metamodules.

    This object can then be :spawn()'d into the world.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')
local https = game:GetService('HttpService')

--]] Modules
local types = require(script.types)
local modelWrap = require(script.ModelWrap)

local interactable = require(replicatedStorage.Shared.Interactable)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache
local cdn = sawdust.core.cdn

--> Networking
local world = networking.getChannel('world')

--> Cache
local item_cache = cache.findCache('items')

local interactable_cache = cache.findCache('interactable')
local objects_cache = interactable_cache:findTable('objects')

--> CDN
local item_cdn = cdn.getProvider('item')

--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Item Base
local item = {}
item.__index = item

--[[ item.new(id: string) : Item
    Constructor function for a new item.
    "id" argument must match an asset located in content.item, which
    will control the appearance & behavior for this item. ]]
function item.new(id: string, uuid: string?) : types.Item
    local self = setmetatable({} :: types.self_item, item)

    if is_client then
        assert(uuid, `item.new() argument #2 (uuid) missing or nil!`) end
    assert(id, `item.new() argument #1 (id) missing or nil!`)
    assert(type(id)=='string', `item.new() argument #1 (id) is of type {type(id)}, it was expected to be a string.`)
    assert(item_cdn:hasAsset(id), `item.new() provided id ({id}) couldn't be found in CDN!`)
    self.id = id
    self.uuid = if is_client then uuid else `{id}.{https:GenerateGUID(false)}`
    
    if not objects_cache:hasEntry(id) then
        local item_asset = item_cdn:getAsset(id)
        local new_object = interactable.newObject{
            object_id = `item.{id}`,
            object_name = item_asset.appearance.name,

            instance = {workspace.items}
        }
    end
    
    if is_client then
        local found_model = workspace.items:WaitForChild(uuid)
        assert(found_model, `Failed to locate item in folder! ({uuid})`)

        self.model = modelWrap.new(found_model)
    else
        self.model = modelWrap.new(item_cdn:getAsset(id).appearance.model:Clone())
        self.model.instance.Name = self.uuid
        self.model.instance.Parent = workspace.items
        world.item:with()
            :broadcastGlobally()
            :intent('instantiate')
            :data(self.id, self.uuid)
            :fire()
    end

    item_cache:setValue(self.uuid, self)
    return self
end

--[[ item:setTransform(transform: CFrame)
    Sets the transform of this item to the specified Transform CFrame. ]]
function item:setTransform(transform: CFrame, update_clients: boolean)
    if update_clients==nil then update_clients=true end

    assert(transform, `item:setTransform() argument #1 (transform) missing or nil!`)
    self.model:setTransform(transform)
    self.transform = transform
    if not is_client and update_clients==true then
        world.item:with()
            :broadcastGlobally()
            :intent('transform')
            :data(self.uuid, transform)
            :fire()
    end
end

--[[ item:pickup(player: Player?)
    This will pick up this item for the specified player. ]]
function item:pickup(player: Player?)
    if not is_client then
        assert(player, `item:pickup() argument #1 (player) missing or nil!`)
        return true
    else
        local s, payload = world.item:with()
            :intent('pickup')
            :data(self.uuid)
            :invoke():wait()
        if s then return true
        else
            warn(`Failed to pick up item w/ uuid {self.uuid}`)
            if payload then
                warn(`A message was provied: {payload}`) end
        return end
    end
end

return item