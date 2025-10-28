--[[

    Objective Interface

    Griffin Dalby
    2025.10.28

    This module will provide a comprehensive interface to handle
    objective prompts for players.

--]]

--]] Services
--]] Modules
local types = require(script.types)
local util  = require(script.util)

--]] Sawdust
--]] Settings
local package_list = {
    ['types'] = script.types,
    ['condition'] = script.condition,
}

--]] Constants
--]] Variables
--]] Functions
--]] Module
local objective = {}
objective.__index = objective

--> Package Utilities
function objective.withConditions()
    return objective, require(package_list.condition) end

--> Objective Behavior
function objective.new(objective_settings: types.ObjectiveSettings) : types.Objective
    util.sanitize.settings_objective(objective_settings)

    local self = setmetatable({}::types.self_objective, objective)

    self.id = objective_settings.id
    self.conditions = objective_settings.conditions

    return self
end

return objective