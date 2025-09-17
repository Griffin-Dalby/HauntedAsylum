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

--]] Modules
local types = require(script.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local cache = sawdust.core.cache
local cdn = sawdust.core.cdn

--> Cache
local item_cache = cache.findCache('items')

--> CDN
local item_cdn = cdn.getProvider('item')

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Item Base
local item = {}
item.__index = item

function item.new(id: string) : types.Item
    local self = setmetatable({} :: types.self_item, item)

    assert(id, `item.new() argument #1 (id) missing or nil!`)
    assert(type(id)=='string', `item.new() argument #1 (id) is of type {type(id)}, it was expected to be a string.`)
    assert(item_cdn:hasAsset(id), `item.new() provided id ({id}) couldn't be found in CDN!`)
    self.id = id

    return self
end

return item