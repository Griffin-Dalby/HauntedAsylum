--[[

    Item Example Data

    Griffin Dalby
    2025.09.17

    This module will show an example for item data.

--]]

local __item = require(script.Parent.__item)
local example = {} :: __item.ItemTemplate

example.appearance = {
    model = script.example,
    name = 'Example'
}

return example