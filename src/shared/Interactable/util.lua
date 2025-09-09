--[[

    Interactable Helper Module

    Griffin Dalby
    2025.09.08

    This module will provide helper functions to prevent boilerplate
    within the interaction system.

--]]

--]] Services
--]] Modules
--]] Settings
local _default_prompt_defs = {
    interact_gui = '',
    interact_bind = { Enum.KeyCode.E, Enum.KeyCode.ButtonX },

    range = 7.5,
    raycast = true,

    hold_time = 1,
}

--]] Constants
--]] Variables
--]] Functions
--]] Helper

local helper = {}

--]] Verification
helper.verify = {}
helper.verify.prompt_defs = function(prompt_defs: {})
    local _dpd_ = _default_prompt_defs

    for i, v in pairs(prompt_defs) do
        if not _dpd_[i] then
            warn(`[verify.prompt_defs] Invalid prompt_def key found! This will be omitted. (Caught: {i})`)
            prompt_defs[i] = nil; continue end

        if not (type(v) ~= type(_dpd_[i]))
            and not (typeof(v) ~= typeof(_dpd_[i])) then
                warn(`[verify.prompt_defs] prompt_def key found w/ invalid type! This will be defaulted. ({i} is a {type(v)}/{typeof(v)}; expected {type(_default_prompt_defs[i])}/{typeof(_default_prompt_defs[i])}.`)
                prompt_defs[i] = _dpd_[i]; continue end
    end
end

helper.verify.player_table = function(players: {}) : {[number]: Player}
    local clean = {}
    for i, inst in pairs(players) do
        if typeof(inst) ~= 'Instance' or not inst:IsA('Player') then
            error(`Key in Player Table @ #{i} isn't a player!`)
            continue; end

        table.insert(clean, inst)
    end

    return clean
end

return helper