--[[

    Entity Metrics

    Griffin Dalby
    2025.11.06

    Provides a comprehensive interface to track & parse metrics for entity
    brain mapping.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local learn_types = require(script.Parent.learning.types)
local entity_types = require(script.Parent.types)

--]] Sawdust


--]] Settings
local metrics_enabled = true

--]] Constants
--]] Variables
--]] Functions
--]] Module
local metrics = {}
metrics.__index = metrics

function metrics.hook(entity: entity_types.Entity<{}>) : entity_types.EntityMetrics
    local self = setmetatable({} :: entity_types.self_metrics, metrics)

    self.id = entity.id
    self.parameter = {}
    self.e_parameter = {}

    entity.fsm.environment['metrics'] = self
    return self
end

function metrics:parseParameterUpdate(parameters: { [string]: learn_types.LearningParameter })
    if not metrics_enabled then return end
   
    local this_update = {}
    for name, param in pairs(parameters) do
        this_update[name] = param.value end

    table.insert(self.parameter, this_update)

    --> Check for BrainView
    local r_brainview: RemoteEvent = replicatedStorage:FindFirstChild('__brainview_metrics')
    if r_brainview then
        r_brainview:FireAllClients(
            {self.id, 'parameter'}, 
            #self.parameter, 
            this_update
        )
    end
end

function metrics:onParameterUpdate(callback: (param_list: {}) -> nil)
    table.insert(self.e_parameter, callback)
    return #self.e_parameter
end

return metrics