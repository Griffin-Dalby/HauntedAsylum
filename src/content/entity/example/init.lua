--[[

    Entity Example Data

    Griffin Dalby
    2025.09.16

    This module will show an example for entity data.

--]]

local players = game:GetService('Players')

local __entity = require(script.Parent.__entity)
local example = {} :: __entity.EntityTemplate

example.appearance = {
    model = script.example,
    name = 'Example'
}

example.behavior = {
    spawn_points = { workspace.EntitySpawn },

    find_target = function(model: Model)
        local root_part = model.PrimaryPart
        local player_list = players:GetPlayers()
        local last_max = {math.huge, nil}
        for _, player: Player in pairs(player_list) do
            if not player.Character then continue end
            local target_root = player.Character.PrimaryPart

            local dist = (target_root.Position-root_part.Position).Magnitude
            if dist < last_max[1] then
                last_max = {dist, target_root} end
        end

        if last_max[2] == nil then return end
        return last_max[2]
    end
}

example.data = {
}

return example