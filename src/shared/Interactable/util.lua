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
    interact_bind = { desktop = Enum.KeyCode.E, console = Enum.KeyCode.ButtonX },

    range = 12.5,
    raycast = true,
    authorized = true,

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
        if i=='interact_gui' then continue end

        if not _dpd_[i] then
            warn(`[verify.prompt_defs] Invalid prompt_def key found! This will be omitted. (Caught: {i})`)
            prompt_defs[i] = nil; continue end

        if (type(v) ~= type(_dpd_[i]))
            and (typeof(v) ~= typeof(_dpd_[i])) then
                warn(`[verify.prompt_defs] prompt_def key found w/ invalid type! This will be defaulted. ({i} is a {type(v)}/{typeof(v)}; expected {type(_default_prompt_defs[i])}/{typeof(_default_prompt_defs[i])}.`)
                prompt_defs[i] = _dpd_[i]; continue end
    end

    for i, v in pairs(_dpd_) do
        if not prompt_defs[i] then
            prompt_defs[i] = v end
    end
end

helper.verify.player_table = function(players: {}) : {[number]: Player}
    local clean = {}
    for i, inst in pairs(players) do
        if typeof(inst) ~= 'Instance' or not inst:IsA('Player') then
            error(`Key in Player Table @ #{i} isn't a player!`)
        end

        table.insert(clean, inst)
    end

    return clean
end

helper.verify.instance = function(provided) : Instance | {Instance}
    if type(provided) == 'table' then
        local container = provided[1]     :: Instance
        local search_params = provided[2] :: {[string]: any}

        assert(container, `Attempt to search for instance inside nil container!`)
        assert(typeof(container)=='Instance',
            `"container" (arg 1) is of type "{typeof(container)}", expected an instance.`)

        assert(search_params, `Attempt to search for instance with nil search_params!`)
        assert(type(search_params)=='table',
            `"search_params" (arg 2) is of type "{type(search_params)}", expected a table.`)

        --]] Returns true if the search_params fit the provided instance.
        local function consider_params(instance)
            local fail = false
            for param_name, param_value in pairs(search_params) do
                if param_name=='attributes' then
                    for attb_name, attb_value in pairs(param_value) do
                        if not instance:GetAttribute(attb_name) then fail=true; break end
                        if instance:GetAttribute(attb_name)~=attb_value then fail=true; break end
                    end
                    continue
                end
                if fail then break end

                if instance[param_name] ~= param_value then
                    fail = true
                    break end
            end

            return not fail
        end

        local instances = {}
        for _, child in pairs(container:GetChildren()) do
            if not consider_params(child) then continue end
            table.insert(instances, child)
        end

        -- if #instances==0 then
        --     error(`Found 0 instances to attach this object to!`) end
        return instances
    elseif typeof(provided) == 'Instance' then
        return {provided}
    else
        error(`An invalid instance was passed! (Provided Type: {type(provided)}/{typeof(provided)}`)
    end
end

return helper