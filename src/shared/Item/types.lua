--[[

    Item Base Types

    Griffin Dalby
    2025.09.17

--]]

local __ = {}

--[[ ITEM OBJECT ]]--
local item = {}
item.__index = item

export type self_item = {
    id: string,
    uuid: string,
    model: ModelWrap,
}
export type Item = typeof(setmetatable({} :: self_item, item))

function item.new(id: string) : Item end
function item:setTransform(transform: CFrame) end

--[[ MODEL WRAPPER ]]--
local modelWrap = {}
modelWrap.__index = modelWrap

export type self_modelWrap = {}
export type ModelWrap = typeof(setmetatable({}::self_modelWrap, modelWrap))

function modelWrap.new(uuid: string) : ModelWrap end
function modelWrap:transform(transform: CFrame) end

return __