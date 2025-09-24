--[[

    Inventory Replicated Object

    Griffin Dalby
    2025.09.22

    This module will provide logic to control a replicated inventory.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking
local cache = sawdust.core.cache

--> Networking
local mechanics = networking.getChannel('mechanics')

--> Cache
local inventory_cache = cache.findCache('inventory')

--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Objects
local inventory = {}
inventory.__index = inventory

type self = {
    contents: {}
}
export type Inventory = typeof(setmetatable({} :: self, inventory))

function inventory.new(player: Player) : Inventory
    local self = setmetatable({} :: self, inventory)

    self.contents = {}

    if is_client then
        local finished, success = false, false
        mechanics.inventory:with()
            :intent('instantiate')
            :timeout(2)
            :invoke()
                :andThen(function() success = true end)
                :finally(function() finished = true end)
                :catch(function(data)
                    local err = data[1]
                    error(`There was an issue contacting the server for inventory instantiation!`)
                    if err then warn(`An error was provided: {err}`) end
                end)
        
        repeat task.wait(0) until finished
        if not success then return end
    else
        if inventory_cache:hasEntry(player) then
            return false, 'Inventory already exists' end
        
        inventory_cache:setValue(player, self)
    end

    return self
end

return inventory