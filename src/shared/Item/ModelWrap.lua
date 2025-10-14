--[[

    ModelWrap Module

    Griffin Dalby
    2025.10.13

    This module will wrap Models and make transforms much easier

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.Parent.types)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local networking = sawdust.core.networking

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local modelWrap = {}
modelWrap.__index = modelWrap

function modelWrap.new(instance: Instance) : types.ModelWrap
    local self = setmetatable({} :: types.self_modelWrap, modelWrap)

    self.instance = instance

    return self
end

function modelWrap:transform(transform: CFrame)
    if self.instance:IsA('Model') then
        self.instance:PivotTo(transform)
    elseif self.instance:IsA('BasePart') then
        self.instance.CFrame = transform
    else
        error(`Can't find according transformer for {self.instance:GetAttribute('uuid')}`)
    end
end

return modelWrap