--!strict
--[[

    Objective Controller

    Griffin Dalby
    2026.1.27

        This module provides an Objectives Controller, allowing 
    dynamic & safe creation / handling of Objectives, with automatic
    UI generation.

--]]

--]] Services
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

--]] Modules
--]] Sawdust
--]] Settings
--]] Constants
--> Index Player
local player = Players.LocalPlayer
local player_ui = player.PlayerGui

--]] Variables
--]] Functions
--]] Utility Types
type PacketData = {
    appearance: {
        [number]: string,
    },

    conditions: {
        [number]: {
            [number]: string
        }
    },

    id: string
}

--]] Extract UI
--#region | UI Types

type ConditionTemplate = Frame & {
    Description: TextLabel & {
        Dash: Frame
    },
    Checkbox: Frame & {
        Check: TextLabel,
    }    
}

type ObjectiveUI = Frame & {
    Header: Frame & {
        ObjectiveName: TextLabel,
        Description: TextLabel,

        CompletionBar: Frame & {
            Completed: Frame
        }
    },

    Conditions: Frame & {
        [string]: ConditionTemplate
    }
}

--#endregion

local objectives_ui = StarterGui
                       :WaitForChild("UI")
                       :WaitForChild("Objectives")
                       
local objective_template = objectives_ui
                            :WaitForChild("Template") :: ObjectiveUI
objective_template.Parent = script

local condition_template = objective_template
                            :WaitForChild("Conditions")
                            :WaitForChild("Template") :: ConditionTemplate
condition_template.Parent = script

--]] Module
--#region | Module Types
type self_methods = {
    __index: self_methods,

    --]] CONSTRUCTOR

    --[[
        Creates a new Client Objective handler, providing UI control,
        and safe client-side objective knowledge.

        @return ClientObjective
    ]]
    new: (packet_data: PacketData) -> ClientObjective,

    --[[
        Attempts to fetch a specific Client Objective.

        @param objective_id Objective to search for

        @return ClientObjective?
    ]]
    get: (objective_id: string) -> ClientObjective?,

    --[[
        Attempts to fetch a specific Client Objective with the ID of a
        condition contained with the objective.

        @param condition_id Condition to search for

        @return ClientObjective?
    ]]
    getByCondition: (condition_id: string) -> ClientObjective?,

    --]] METHODS

    --[[
        Updates a condition's visual & internal completion state

        @param condition_id ID of the condition to be updated
        @param completed Boolean describing condition's completion status
    ]]
    ConditionUpdated: (self: ClientObjective, condition_id: string, completed: boolean) -> nil,

    --[[
        Checks off this entire objective and clears it.
    ]]
    ObjectiveFinished: (self: ClientObjective) -> nil,
}

type self_fields = {
    id: string,
    ui: ObjectiveUI,

    packet: PacketData,

    conditions: {
        [string]: {
            completed: boolean,
            ui: ConditionTemplate
        }
    }
}

export type ClientObjective = typeof(setmetatable({} :: self_fields, 
                                                  {} :: self_methods))
--#endregion

--=============--
-- CONSTRUCTOR --
--=============--
local ObjectiveCache = {} :: {[string]: ClientObjective}
local ConditionMap = {} :: {[string]: string}

local Objective = {} :: self_methods
Objective.__index = Objective

function Objective.new(packet_data: PacketData)
    local self = setmetatable({} :: self_fields, Objective)

    --]] Extract Data
    local objective_id = packet_data.id
    local objective_appearance = {
        name = packet_data.appearance[1],
        description = {
            short = packet_data.appearance[2],
            long = packet_data.appearance[3]
        }
    }

    self.id = objective_id
    self.packet = packet_data

    --]] Generate UI
    self.ui = objective_template:Clone()
    self.ui.Name = objective_id

    self.ui.Header.ObjectiveName.Text = objective_appearance.name
    self.ui.Header.Description.Text = objective_appearance.description.short

    --]] Parse Conditions
    self.conditions = {}

    for layout_order, condition_data in ipairs(packet_data.conditions) do
        
        local condition_id = condition_data[1]
        local condition_description = condition_data[2]

        --> Create UI
        local new_condition = condition_template:Clone()
        new_condition.Name = condition_id
        new_condition.Description.Text = condition_description

        new_condition.LayoutOrder = layout_order
        new_condition.Parent = self.ui.Conditions
        new_condition.Visible = true

        --> Save in Objective
        self.conditions[condition_id] = {
            completed = false,
            ui = new_condition
        }

        ConditionMap[condition_id] = packet_data.id
    end

    --]] Render UI
    local player_screen = player_ui:WaitForChild("UI")
    self.ui.Parent = player_screen:WaitForChild("Objectives")
    self.ui.Visible = true

    --]] Save to Cache
    ObjectiveCache[objective_id] = self

    return self
end

function Objective.get(objective_id: string)
    return ObjectiveCache[objective_id]
end

function Objective.getByCondition(condition_id: string)
    local mapped = ConditionMap[condition_id]
    if mapped then
        return ObjectiveCache[mapped]
    end

    return nil
end

--=========--
-- METHODS --
--=========--
function Objective:ConditionUpdated(condition_id: string, is_completed: boolean)
    local this_condition = self.conditions[condition_id]
    assert(this_condition~=nil, `Condition w/ id "{condition_id:sub(1, 14)}..." does not exist within objective "{self.id}"!`)

    if this_condition.completed~=is_completed then
        this_condition.completed = is_completed

        --> Check
        this_condition.ui.Checkbox.Check.Visible = is_completed
       
        --> Dash
        if is_completed then
            local description = this_condition.ui.Description
            description.Dash.Size = UDim2.new(0, description.TextBounds.X+8, 0, 4)
        end

        this_condition.ui.Description.Dash.Visible = is_completed

        --> Parse # of completed
        local total_conditions = #self.packet.conditions
        local total_completed = 0
        for _, other_condition in pairs(self.conditions) do
            if other_condition.completed then
                total_completed += 1
            end
        end

        --> Progress bar
        local prog_bar = self.ui.Header.CompletionBar
        prog_bar.Completed.Size = UDim2.new(total_completed/total_conditions, 0, 1, 0)
    end

    return nil
end

function Objective:ObjectiveFinished()

    task.wait(4)
    self.ui:Destroy()

    return nil
end

return Objective