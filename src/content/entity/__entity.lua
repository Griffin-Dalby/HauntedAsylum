--[[

    Entity Data Template

    Griffin Dalby
    2025.09.16

--]]

local __ = {}

export type EntityTemplate = {
    appearance: {
        model: Model,
        name: string,
    },

    behavior: {
        spawn_points: {BasePart}
    }
}

return __