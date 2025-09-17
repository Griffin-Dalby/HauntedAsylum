--[[

    Example Entity Descriptor

    Griffin Dalby
    2025.09.16

    This module provides an example for entity meta.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local entity = require(replicatedStorage.Shared.Entity)

return function()

    local self = entity.new({ id='test', name='Test Entity' })

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

    self.chase = self.fsm:event('chase')
        :hook('enter', function(env)
            
        end)
        :hook('exit', function(env)
        
        end)

    return self

end