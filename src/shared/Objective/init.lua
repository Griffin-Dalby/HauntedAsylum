--[[

    Objective Interface

    Griffin Dalby
    2025.10.28

    This module will provide a comprehensive interface to handle
    objective prompts for players.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local types = require(script.types)
local util  = require(script.util)

local condition_tester = require(script.__condition_tester)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)

local signal = sawdust.core.signal
local cache = sawdust.core.cache

--> Cache
local players_cache = cache.findCache('players')
local session = players_cache:findTable('session')

local objective_cache = cache.findCache('objectives')

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

    --> Create & Run Condition Tester
    self.tester = condition_tester.new()
    self.tester:runTests(objective_settings.conditions) --> Strict tests for conditions
    
    --> Fill Objective Data
    self.id = objective_settings.id
    self.name = objective_settings.name
    self.description = objective_settings.description
    self.conditions = objective_settings.conditions

    self.__fulfilled = objective_settings.fulfilled

    --> Create Completion Signal
    local emitter = signal.new()

    self.completed = emitter:newSignal()
    self.completed:connect(function(player: Player)
        print(`Objective [{self.id}] completed by player [{player.Name}]`)
        local next_objective_id = self.__fulfilled(true)
        if not objective_cache:hasEntry(next_objective_id) then
            error(`Objective [{next_objective_id}] does not exist! Cannot switch for player [{player.Name}] (from [{self.id}])`)
            return end

        if next_objective_id then
            print(`Switching to Objective [{next_objective_id}] for player [{player.Name}]`)

            assert(session:hasEntry(player), `No session data for player [{player.Name}]`)
            local player_session = session:getValue(player)

            player_session.current_objective = objective_cache:getValue(next_objective_id)
        end
    end)

    objective_cache:setValue(self.id, self)
    return self
end

function objective:update(player: Player): boolean
    local conditions_met = 0
    local conditions_total = #self.conditions

    for _, condition: types.Condition in pairs(self.conditions) do
        if condition:update(player) then
            conditions_met+=1 end
    end

    local all_conditions_met = conditions_met==conditions_total
    if all_conditions_met then
        self.completed:fire(player) end

    return all_conditions_met
end

return objective