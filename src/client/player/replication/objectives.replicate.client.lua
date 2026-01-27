--!strict
--[[

    Objective Client Controller

    Griffin Dalby
    2025.10.28

    This script will control the objectives system for the client-side.

--]]

--]] Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--]] Modules
local PlayerScripts = script.Parent.Parent
local PlayerLogic = PlayerScripts.logic

local ClientObjectives = require(PlayerLogic.objectives)

--]] Sawdust
local Sawdust = require(ReplicatedStorage.Sawdust)

local Networking = Sawdust.core.networking

--> Networking
local GameChannel = Networking.getChannel("game")

--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Controller

--> Setup Router
GameChannel.objective:route()
    :on('completed_objective', function(req)

        local objective_id = req.data[1]
        local found_objective = ClientObjectives.get(objective_id)

        if found_objective then
            found_objective:ObjectiveFinished()
        else
            warn(`[{script.Name}] Failed to locate Objective w/ ID: "{objective_id}"!`)
        end

    end)
    :on('update_condition', function(req)

        local condition_id = req.data[1]
        local condition_completed = req.data[2] :: boolean
        
        local found_objective = ClientObjectives.getByCondition(req.data[1])

        if found_objective then
            found_objective:ConditionUpdated(condition_id, condition_completed)
        else
            warn(`[{script.Name}] Failed to locate Objective by condition w/ ID: "{condition_id:sub(1, 14)}..."!`)
        end

    end)
    :on('new', function(req)

        local objective_data = req.data

        print(objective_data)
        ClientObjectives.new(req.data)

    end)
