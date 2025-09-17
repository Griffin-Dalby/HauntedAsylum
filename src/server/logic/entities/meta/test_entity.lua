--[[

    Example Entity Descriptor

    Griffin Dalby
    2025.09.16

    This module provides an example for entity meta.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local entity = require(replicatedStorage.Shared.Entity)

local sawdust = require(replicatedStorage.Sawdust)
local cdn = sawdust.core.cdn

local entity_provider = cdn.getProvider('entity')

return function()

    local self = entity.new('example')

    --] Define States
    --#region
    self.idle
        :hook('enter', function(env)
        
        end)
        :hook('exit', function(env)
        
        end)
        :hook('update', function(env)
            
        end)

    self.patrol
        :hook('enter', function(env)
    
        end)
        :hook('exit', function(env)
        
        end)
        :hook('update', function(env)  
        
        end)

    self.chase = self.fsm:state('chase')
        :hook('enter', function(env)
            
        end)
        :hook('exit', function(env)
        
        end)

    --#endregion

    self:spawn()

    return self

end