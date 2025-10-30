--[[

    Intro Storyline Objectives

    Griffin Dalby
    2025.10.29

    This will provide the full storyline for the intro objectives.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
local objective, condition = require(replicatedStorage.Shared.Objective).withConditions()

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local area1, area2, area3 = workspace:WaitForChild('Area1'), workspace:WaitForChild('Area2'), workspace:WaitForChild('Area3')

return function()
    local intro_objectives = {}
    
    intro_objectives[1] = objective.new({
        id = 'intro_001', --> Internal ID to call to this objective
        name = 'Orientation', --> Name visible w/ objective
        description = {
            short = 'Get accustomed with the surroundings.', --> HUD Description
            long = 'Welcome to the Haunted Asylum! Get familiar with your environment, can\'t have you wandering off.', --> Objective Log Description
        },

        conditions = {
            [1] = condition.new({desc='Stand in the Green Area'}, function(identity) --> First condition that must be met
                return identity.player:inArea(area1) --> Simple abstracted checks to make this easy
            end)
        },
        fulfilled = function(is_fulfilled: boolean) --> What happens when this objective is complete?
            if is_fulfilled then
                print('Objective 1 Fulfilled!')
                return 'intro_002' --> Returning a string will give the player that objective next.
            end
        end
    })

    intro_objectives[2] = objective.new({
        id = 'intro_002',
        name = 'Exploration',
        description = {
            short = 'Explore the next area.',
            long = 'Great job on getting familiar! Now, enter the red area.',
        },
        conditions = {
            [1] = condition.new({desc='Stand in the Red Area'}, function(identity)
                return identity.player:inArea(area2) and not identity.player:inArea(area1) --> Ensure player is not in red & green
            end)
        },
        fulfilled = function(is_fulfilled: boolean)
            if is_fulfilled then
                print('Objective 2 Fulfilled!')
                return 'intro_003'
            end
        end
    })

    intro_objectives[3] = objective.new({
        id = 'intro_003',
        name = 'Final Approach',
        description = {
            short = 'Mixing shades',
            long = 'Enter the yellow area, in between the green and red zones.',
        },
        conditions = {
            [1] = condition.new({desc='Stand in the Green Area'}, function(identity)
                return identity.player:inArea(area1)
            end),
            [2] = condition.new({desc='Stand in the Red Area'}, function(identity)
                return identity.player:inArea(area2)
            end),
        },
        fulfilled = function(is_fulfilled: boolean)
            if is_fulfilled then
                print('Objective 3 Fulfilled!')
                return 'intro_004'
            end
        end
    })

    intro_objectives[4] = objective.new({
        id = 'intro_004',
        name = 'Completion',
        description = {
            short = 'Conquer the three areas.',
            long = 'Now, you must stand in all three areas at once.',
        },
        conditions = {
            [1] = condition.new({desc='Stand in the Green area.'}, function(identity)
                return identity.player:inArea(area1)
            end),
            [2] = condition.new({desc='Stand in the Red area.'}, function(identity)
                return identity.player:inArea(area2)
            end),
            [3] = condition.new({desc='Stand in the Blue area.'}, function(identity)
                return identity.player:inArea(area3)
            end),
        },
        fulfilled = function(is_fulfilled: boolean)
            if is_fulfilled then
                print('Intro Objectives Completed!')
                return nil --> No next objective
            end
        end
    })

    return intro_objectives
end