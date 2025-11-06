--[[

    Entity Parameter

    Griffin Dalby
    2025.11.05

    This module provides a "parameter" object that can easily be scaled,
    adjusted, or read from.

--]]

--]] Services
--]] Modules
local learn_types = require(script.Parent.types)

--]] Sawdust
--]] Settings
local __debug = true

--]] Constants
--]] Variables
--]] Functions
function processNumber(n: number, weight: string)
    local op = weight:sub(1,1)
    local num = tonumber(weight:sub(2))
    assert(num, `Failed to convert weight string to number! (Parsing: {num})`)

    if op=="+" then
        return n+num
    elseif op=="-" then
        return n-num
    else
        warn(debug.traceback(`Invalid operator "{op}"!`, 3))
        return nil
    end
end

function verifyData(data: learn_types.ParameterData)
    --> Ensure Existence
    local function exists(v: any?, path: string)
        assert(v~=nil, `Parameter ({path}) is undefined!`) end
    exists(data.def, `.def: number`)
    exists(data.lim, `.lim: table`)
    exists(data.lim.min, `.lim.min: number`)
    exists(data.lim.max, `.lim.max: number`)
    exists(data.weights, `.weights: table`)

    --> Validate Types
    local function v_type(v: any?, t: string, path: string)
        assert(type(v)==t, `Parameter ({path}) is of type "{type(v)}"! (expected {t})`) end

    v_type(data.def, 'number', '.def')
    v_type(data.lim, 'table', '.lim')
    v_type(data.lim.max, 'number', '.lim.max')
    v_type(data.lim.min, 'number', '.lim.min')
    v_type(data.weights, 'table', '.weights')

    --> Bounds
    assert(data.lim.min < data.lim.max, `Minimum Limit is a higher number than Maximum Limit! ({data.lim.min} > {data.lim.max})`)
    assert(data.def > data.lim.min and data.def < data.lim.max, `Default Weight ({data.def}) is outside of bounds! ({data.lim.min}-{data.lim.max})`)
end

--]] Module
local parameter = {}
parameter.__index = parameter

function parameter.new(id: string, data: learn_types.ParameterData) : learn_types.LearningParameter
    verifyData(data)

    local self = setmetatable({} :: learn_types.self_parameter, parameter)

    self.id = id

    self.value = data.def
    self.limit = data.lim
    self.weights = data.weights

    return self
end

function parameter:process(event_id: string)
    local weight = self.weights[event_id]
    if weight then
        local processed = processNumber(self.value, weight)
        if not processed then return end

        self.value = processed
        if __debug then
            print(`[{script.Name}({self.id})] Processed event "{event_id}" ({self.value}\{{weight}})`)
        end
    end
end

return parameter