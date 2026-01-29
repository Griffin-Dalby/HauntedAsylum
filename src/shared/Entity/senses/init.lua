--[[

    Entity Senses

    Griffin Dalby
    2025.11.02

    This module will provide entity behaviors with senses, abstracted
    algorithims for tedious things, making entity behavior charting
    simple & seamless.

    This hooks into the state machine environment.

--]]

--]] Services
--]] Modules
local entity_types = require(script.Parent.types)
local sense_types = require(script.types)

--]] Sawdust
--]] Settings
local _debug = false

local sense_packages = {
    ['player'] = script:WaitForChild('sense.player'),
    ['physical'] = script:WaitForChild('sense.physical'),
    ['asylum'] = script:WaitForChild('sense.asylum')
}

local sData_flags = {
    ['is_hiding'] = true
}

--]] Constants
--]] Variables
--]] Functions
local package_verifier = {
    ['player'] = function(settings: sense_types.SensePlayerSettings, entity_id: string)
        local log_tag = `[{entity_id}.package.player]`

        --> Validate defaults
        settings.blacklist = settings.blacklist or {}
        settings.filterType = settings.filterType or 'exclude'
        settings.sessionDataFlags = settings.sessionDataFlags or {['is_hiding']=true} --> Omit players hiding

        --> Validate types
        assert(typeof(settings.blacklist)=='table', `{log_tag} settings.blacklist is of type "{typeof(settings.blacklist)}", but expected a table!`)
        assert(type(settings.filterType)=='string', `{log_tag} settings.filterType is of type "{type(settings.filterType)}", but expected a string!`)
        assert(type(settings.sessionDataFlags)=='table', `{log_tag} settings.sessionDataFlags is of type "{type(settings.sessionDataFlags)}", but expected a table!`)

        --#region

        --> Validate filterType
        assert(settings.filterType=='include' or settings.filterType=='exclude', `{log_tag} settings.filterType is set to "{settings.filterType}"! It must be either "exclude" or "include"!`)
        
        --> Validate blacklist
        for i, player: Player in ipairs(settings.blacklist) do
            if typeof(player)~="Instance" or not player:IsA('Player') then
                warn(debug.traceback(`{log_tag} settings.blacklist[{i}] is of type "{typeof(player)=="Instance" and player.ClassName or typeof(player)}", put expected a Player (Instance). Omitting from blacklist!`, 3)) 
                table.remove(settings.blacklist, player); continue end
        end

        --> Validate sessionDataFlags
        for i, flag: string in ipairs(settings.sessionDataFlags) do
            if not sData_flags[flag] then
                warn(debug.traceback(`{log_tag} settings.sessionDataFlags[{i}] doesn't have an exposed flag for "{i}"! (Possibly a typo / not yet registered?)`, 3))
                settings.sessionDataFlags[i] = nil; continue end
        end

        --#endregion
    end,
    ['physical'] = function(settings: sense_types.SensePhysicalSettings, entity_id: string)
        local log_tag = `[{entity_id}.package.physical]`
    end,
    ['asylum'] = function(settings: sense_types.SenseAsylumSettings, entity_id: string)
        local log_tag = `[{entity_id}.package.asylum]`
    end
}
function verifySettings(settings: sense_types.SensePackages, entity_id: string)
    for package_name: string, package_settings: {} in pairs(settings) do
        local verifier = package_verifier[package_name]
        if verifier then
            verifier(package_settings, entity_id)
        else
            error(`An invalid package was provided for entity "{entity_id}"! (With name "{package_name or "< none >"}")!`)
        end
    end
end

--]] Senses
local cortex = setmetatable({}, {
    __index = function(t, idx)
        local val = rawget(t, idx)
        if val ~= nil then return val end

        if sense_packages[idx] then
            warn(debug.traceback(`[{script.Name}] Attempt to access package ({idx}) that wasn't added to the entities sense packages!`, 3))
            warn(`[{script.Name}] To resolve this, head to the definition of the "{t.id}" entity, and provide settings for the "{idx}" sense.`)
        end

        return nil
    end
})

function cortex.hook(entity: entity_types.Entity<entity_types.FSM_CortexInject>, sense_settings: sense_types.SensePackages)
    local self = setmetatable({} :: sense_types.self_cortex, cortex)
    
    verifySettings(sense_settings, entity.id)
    self.__settings = sense_settings

    --> Parse Settings
    for sense_name: string, _settings: {} in pairs(self.__settings) do
        if not sense_packages[sense_name] then
            warn(debug.traceback(`[{script.Name}] Failed to find sense package w/ name "{sense_name}"!`))
            continue end

        self[sense_name] = require(sense_packages[sense_name])(self)
    end

    self.injectRig = function(rig: entity_types.EntityRig)
        assert(not self.__body, `Rig has already been injected into this cortex!`)
        self.__body = rig.model end
    entity.fsm.environment['senses'] = self
end

return cortex