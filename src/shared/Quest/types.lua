--[[

    Quest Interface Types

    Griffin Dalby
    2025.10.15

    Provides typechecking for the Quest interface.

--]]

local __ = {}

--[[ QUEST ]]--
local quest = {}
quest.__index = quest

export type self_quest = {}
export type Quest = typeof(setmetatable(({}::self_quest),quest))

function quest.new() : Quest end

return __