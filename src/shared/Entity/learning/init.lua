--[[

    Entity Learning Module

    Griffin Dalby
    2025.11.05

    This module will provide a simple learning system that allows monsters
    to adapt with personalized parameters that tie into behavioral charting.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local learning = {}
learning.__index = learning

function learning.hook(entity: types.Entity<{}>, parameters: types.LearningParameters) : types.EntityLearning
    local self = setmetatable({} :: types.self_learning, learning)

    self.parameters = parameters

    entity.fsm.environment['learn'] = self
    return self
end

function learning:adjustParameter(param_id: string, ...)
    local param: types.LearningParameter = self.parameters[param_id]
    assert(param, `[{script.Name}] Invalid parameter name "{param_id}"!`)

    --> Entity has control of how parameters adjust themselfs
    self.parameters[param_id] = param.adj(...)
end

return learning