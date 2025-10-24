--[[

    Session Player Data Template

    Griffin Dalby
    2025.09.17

--]]

local session = {
    inventory = {
        tools = { },
        items = { },
        notes = { },
    },

    is_hiding = false,
}

export type session_template = typeof(session)
return session