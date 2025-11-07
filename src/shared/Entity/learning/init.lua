--[[

    Entity Learning Module

    Griffin Dalby
    2025.11.05

    This module will provide a simple learning model that allows entities
    to dynamically adapt according to charted stimuli using a rule-based
    reinforced model.

--]]

--]] Services
--]] Modules
local learn_types = require(script.types)
local entity_types = require(script.Parent.types)

local IParameter = require(script.parameter)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local learning = {}
learning.__index = learning

function learning.hook(entity: entity_types.Entity<{}>, parameters: {[string]: learn_types.ParameterData}) 
        : learn_types.LearningModel
    local self = setmetatable({} :: learn_types.self_model, learning)
    self.__metrics = entity.fsm.environment['metrics']

    --> Initalize Parameters
    local init_params = {}
    for name, data in pairs(parameters) do
        init_params[name] = IParameter.new(name, data)
    end
    self.parameters = init_params

    entity.fsm.environment['learn'] = self
    return self
end

function learning:process(event_id: string)
    for _, param: learn_types.LearningParameter in pairs(self.parameters) do
        param:process(event_id)
    end

    self.__metrics:parseParameterUpdate(self.parameters)
end

function learning:getParam(parameter_name: string)
    assert(parameter_name, `Argument #1 "parameter_name" was not provided!`)
    assert(type(parameter_name)=='string', `Argument #1 "parameter_name" is of type "{type(parameter_name)}"! (expected string)`)

    local found_param = self.parameters[parameter_name] :: learn_types.LearningParameter
    assert(found_param, `Failed to find parameter w/ name "{parameter_name}"!`)

    return found_param
end

return learning