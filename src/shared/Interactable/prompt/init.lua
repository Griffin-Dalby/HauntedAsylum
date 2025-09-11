--[[

    Interactable Prompt

    Griffin Dalby
    2025.09.07

    This module will provide the behavior for Interactable Prompts.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')
local runService = game:GetService('RunService')

--]] Modules
local types = require(script.Parent.types)
local util = require(script.Parent.util)

--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)
local signal = sawdust.core.signal
local cache = sawdust.core.cache

-- Cache
local interactable_cache = cache.findCache('interactable')
local prompt_ui_cache = interactable_cache:createTable('prompt.ui')

--]] Settings
--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Object
local prompt = {}
prompt.__index = prompt

function prompt.new(opts: types._prompt_options, inherited_defs: types._prompt_defs & { instance: Instance }): types.InteractablePrompt
    local self = setmetatable({} :: types._self_prompt, prompt)

    self.prompt_id = opts.prompt_id
    self.action = opts.action
    
    self.prompt_defs = opts.prompt_defs or {}
    util.verify.prompt_defs(self.prompt_defs)

    if inherited_defs then
        for i, v in pairs(inherited_defs) do
            if not self.prompt_defs[i] then
                self.prompt_defs[i] = v end
        end
    end

    if is_client then
        local i_gui = self.prompt_defs.interact_gui

        assert(i_gui, `There was no interact_gui passed to prompt.new() PromptDefs!`)
        
        local builder
        if type(i_gui) == 'string' then
            assert(prompt_ui_cache:hasEntry(i_gui),
                `Failed to find PromptUi in cache w/ ID "{i_gui}"!`)
            builder = prompt_ui_cache:getValue(i_gui)
            print(builder)
        else  
            builder = i_gui
        end

        assert(builder, `There was no PromptUI builder found! Abandoning prompt creation.`)
        self.interact_gui = builder
    end

    self.cooldown = opts.cooldown or 0
    self.require_authority = opts.require_authority or false

    self.disabled_clients = {}
    self.enabled = false

    --] Emitter
    local emitter = signal.new()
    self.triggered = emitter:newSignal()

    self.action_update = emitter:newSignal()
    self.targeted_update = emitter:newSignal()
    self.p_defs_update = emitter:newSignal()
    self.cooldown_update = emitter:newSignal()
    self.disabled_clients_update = emitter:newSignal()

    --] Setup UI
    if is_client then
        self.prompt_ui = self.interact_gui:compile()

        self.prompt_ui:set_object(self.prompt_defs.object_name)
        self.prompt_ui:set_action(opts.action)
    end
    
    
    return self
end

--[[ VISIBILITY ]]--
function prompt:enable()
    self.enabled = true
    if is_client then
        self.prompt_ui:render(self.prompt_defs.instance)
    end
end

function prompt:disable()
    self.enabled = false
    if is_client then
        self.prompt_ui:unrender()
    end
end

--[[ DATA CONTROLS ]]--
--#region
function prompt:setAction(new_action: string)
    assert(new_action, `attempt to :setAction() to nil!`)
    assert(type(new_action) == 'string', `attempt to :setAction() to an invalid type "{type(new_action)}"! (expected a string.)`)

    self.action = new_action
    self.action_update:fire(new_action)
    self.prompt_ui:set_action(new_action)
end

function prompt:setTargeted(targeted: boolean)
    assert(targeted~=nil, `attempt to :setTargeted() to nil!`)
    assert(type(targeted) == 'boolean', `attempt to :setTargeted() to an invalid type "{type(targeted)}"! (expected a boolean.)`)

    self.targeted = targeted
    self.targeted_update:fire(targeted)
    self.prompt_ui:set_targeted(targeted)
end

function prompt:setPromptDefs(new_defs: types._prompt_defs)
    assert(new_defs, `attempt to :setPromptDefs() to nil!`)
    assert(type(new_defs) == 'table', `attempt to :setPromptDefs() to a non-table!`)
    util.verify.prompt_defs(new_defs)
    
    self.prompt_defs = new_defs
    self.p_defs_update:fire(new_defs)
end

function prompt:setCooldown(seconds: number)
    seconds = seconds or 0
    assert(type(seconds) == 'number', `attempt to :setCooldown() to an invalid type "{type(seconds)}"! (expected a number.)`)

    self.cooldown = seconds
    self.cooldown_update:fire(seconds)
end

function prompt:disableForPlayers(...: Player)
    local compiled = {...}
    local players = util.verify.player_table(compiled)

    for _, player in pairs(players) do
        self.disabled_clients[player] = true
    end
    self.disabled_clients_update:fire(self.disabled_clients)
end

function prompt:enableForPlayers(...: Player)
    local compiled = {...}
    local players = util.verify.player_table(compiled)

    for _, player in pairs(players) do
        self.disabled_clients[player] = nil
    end
    self.disabled_clients_update:fire(self.disabled_clients)
end

function prompt:destroy()
    
end

--#endregion

return prompt