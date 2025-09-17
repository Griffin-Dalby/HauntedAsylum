--[[

    Item Base Types

    Griffin Dalby
    2025.09.17

--]]

local __ = {}

--[[ ITEM OBJECT ]]--
local item = {}
item.__index = item

export type self_item = {}
export type Item = typeof(setmetatable({} :: self_item, item))

function item.new(id: string) : Item end

return __