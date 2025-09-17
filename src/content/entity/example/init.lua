--[[

    Entity Example Data

    Griffin Dalby
    2025.09.16

    This module will show an example for entity data.

--]]

local __entity = require(script.Parent.__entity)
local example = {} :: __entity.EntityTemplate

example.appearance = {
    model = script.example,
    name = 'Example'
}

example.behavior = {
    spawn_points = { workspace.EntitySpawn }
}

example.data = {
}

return example