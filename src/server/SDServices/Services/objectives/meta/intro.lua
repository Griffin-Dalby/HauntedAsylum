--[[

    Intro Storyline Objectives

    Griffin Dalby
    2025.10.29

    This will provide the full storyline for the intro objectives.

--]]

--]] Services
local ServerScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService('ReplicatedStorage')
local asylum = require(ServerScriptService.SDServices.Services.asylum)

--]] Modules
local objective, condition = require(replicatedStorage.Shared.Objective).withConditions()

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
return function()
    local intro_objectives = {}
    
    intro_objectives[1] = objective.new({
        id = 'intro_001', --> Internal ID to call to this objective
        name = 'Find Gonjijam', --> Name visible w/ objective
        description = {
            short = 'Find & Enter the Asylum', --> HUD Description
            long = 'Just entering the forest, we now need to locate Gonjijam.', --> Objective Log Description
        },

        conditions = {
            [1] = condition.new({desc='Enter the Asylum'}, function(identity) --> First condition that must be met
                return identity.asylum:inRoom('1-main_L')
                    or identity.asylum:inRoom('1-main_Lhall')
                    or identity.asylum:inRoom('1-main_R')
                    or identity.asylum:inRoom('office') --> Simple abstracted checks to make this easy
            end)
        },
        fulfilled = function(is_fulfilled: boolean) --> What happens when this objective is complete?
            if is_fulfilled then
                return 'intro_002' --> Returning a string will give the player that objective next.
            end
        end
    })

    intro_objectives[2] = objective.new({
        id = 'intro_002',
        name = 'Explore the Asylum',
        description = {
            short = 'Explore the Second Floor',
            long = 'Check out the offices, and then find the stairwell.',
        },
        conditions = {
            [1] = condition.new({desc='Enter the Office'}, function(identity)
                return identity.asylum:inRoom('1-office') or identity.asylum:onFloor('2')
            end),
            [2] = condition.new({desc='Enter the 2nd floor'}, function(identity)
                return identity.asylum:onFloor('2')
            end)
        },
        fulfilled = function(is_fulfilled: boolean)
            if is_fulfilled then
                return 'impossible'
            end
        end
    })

    -- intro_objectives[3] = objective.new({
    --     id = 'intro_003',
    --     name = 'Final Approach',
    --     description = {
    --         short = 'Mixing shades',
    --         long = 'Enter the yellow area, in between the green and red zones.',
    --     },
    --     conditions = {
    --         [1] = condition.new({desc='Stand in the Green Area'}, function(identity)
    --             return identity.player:inArea(area1)
    --         end),
    --         [2] = condition.new({desc='Stand in the Red Area'}, function(identity)
    --             return identity.player:inArea(area2)
    --         end),
    --     },
    --     fulfilled = function(is_fulfilled: boolean)
    --         if is_fulfilled then
    --             return 'intro_004'
    --         end
    --     end
    -- })

    -- intro_objectives[4] = objective.new({
    --     id = 'intro_004',
    --     name = 'Completion',
    --     description = {
    --         short = 'Conquer the three areas.',
    --         long = 'Now, you must stand in all three areas at once.',
    --     },
    --     conditions = {
    --         [1] = condition.new({desc='Stand in the Green area.'}, function(identity)
    --             return identity.player:inArea(area1)
    --         end),
    --         [2] = condition.new({desc='Stand in the Red area.'}, function(identity)
    --             return identity.player:inArea(area2)
    --         end),
    --         [3] = condition.new({desc='Stand in the Blue area.'}, function(identity)
    --             return identity.player:inArea(area3)
    --         end),
    --     },
    --     fulfilled = function(is_fulfilled: boolean)
    --         if is_fulfilled then
    --             print('Intro Objectives Completed!')
    --             return 'impossible' --> No next objective
    --         end
    --     end
    -- })
    
    intro_objectives[5] = objective.new({
        id = 'impossible',
        name = 'Impossible',
        description = {
            short = 'Impossible to complete',
            long = 'A objective that is impossible to finished, used as a debugging final destination.'
        },
        conditions = {
            [1] = condition.new({desc='yap yap yap'}, function(identity)
                return false
            end)
        }
    })

    return intro_objectives
end