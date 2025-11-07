--!nocheck
--[[

    Entity Learning Types

    Griffin Dalby
    2025.11.02

    This module will provide types for entity learning, which is 
    a lightweight, parameter-driven reinforcement learning system.

--]]

local types = {}

--[[$ LEARNING MODEL $]]--
--[[ This section covers the entities learning model, where parameters
    are stored, linked, and adjusted appropiately. ]]
local model = {}
model.__index = model

export type self_model = {
    parameters: {[string]: LearningParameter}
}
export type LearningModel = typeof(setmetatable({} :: self_model, model))

function model:process(event_id: string) end
function model:getParam(parameter_name: string)
    : LearningParameter end

--[[ PARAMETER ]]--
--[[ This section covers the parameter object, which allows dynamic
    links to parameter data, and allows easy data mutation. ]]
local parameter = {}
parameter.__index = parameter

export type ParameterData = { 
    def: number,
    lim: { min: number, max: number },
    weights: { [string]: string }
}

export type self_parameter = {
    id: string,

    value: number,
    limit: { min: number, max: number },
    weights: { [string]: string }
}
export type LearningParameter = typeof(setmetatable({} :: self_parameter, model))

function parameter:process(event_id: string) end

return types