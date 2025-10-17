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
local networking = sawdust.core.networking
local signal = sawdust.core.signal
local cache = sawdust.core.cache

-- Networking
local world_channel = networking.getChannel('world')

-- Cache
local interactable_cache = cache.findCache('interactable')
local prompt_ui_cache = interactable_cache:createTable('prompt.ui')

--]] Settings
local __debug = false

--]] Constants
local is_client = runService:IsClient()

--]] Variables
--]] Functions
--]] Object
local prompt = {}
prompt.__index = prompt

type _a_inherited_defs = { instance_table: {Instance}, object_name: string, object_id: string }

--[[ prompt.new(opts: PromptOptions, inherited_defs) : InteractablePrompt
    Constructor function for the prompt object, this will process the
    provided inherited defs & prompt options & create a new prompt.

    If needed on the client, the prompt will be authorized with the
    server in order to start a "Replication Pipeline" of sorts. ]]
function prompt.new(opts: types._prompt_options, inherited_defs: types._prompt_defs & _a_inherited_defs): types.InteractablePrompt
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

        --> Lookup Instance
        self.attached_instances = {}
        local inst_table = inherited_defs.instance_table
        for _, inst in pairs(inst_table) do
            local is_prompt_inst = inst:GetAttribute('prompt_id') == self.prompt_id
            if is_prompt_inst then
                table.insert(self.attached_instances, inst)
            end
        end

        if not self.attached_instances then
            error(`Failed to locate correlating prompt_inst w/ prompt_id!`)
        end
    end

    if is_client then
        --> Locate Builder
        local i_gui = self.prompt_defs.interact_gui

        assert(i_gui, `There was no interact_gui passed to prompt.new() PromptDefs!`)
        
        local builder
        if type(i_gui) == 'string' then
            assert(prompt_ui_cache:hasEntry(i_gui),
                `Failed to find PromptUi in cache w/ ID "{i_gui}"!`)
            builder = prompt_ui_cache:getValue(i_gui)
        else  
            builder = i_gui
        end

        assert(builder, `There was no PromptUI builder found! Abandoning prompt creation.`)
        self.interact_gui = builder

        --> Authorize
        print(self.prompt_defs)
        if self.prompt_defs.authorized==true then
            if __debug then print(`[{script.Name}] Attempting to authorize prompt: {self.prompt_defs.object_id}.{self.prompt_id}`) end

            local s = world_channel.interaction:with()
                :intent('auth')
                :data('prompt', self.prompt_defs.object_id, self.prompt_id)
                :timeout(3)
                :invoke():wait()

            if not s then return end
            if __debug then print(`[{script.Name}] Successfully authorized prompt: {self.prompt_defs.object_id}.{self.prompt_id}`) end
        end
    end

    self.cooldown = opts.cooldown or 0
    self.authorized = if self.prompt_defs.authorized~=nil then self.prompt_defs.authorized else true

    self.disabled_clients = {}
    self.enabled = false

    self.active_cooldowns = {}

    --] Emitter
    local emitter = signal.new()
    self.pre_trigger = emitter:newSignal()
    self.triggered = emitter:newSignal()

    self.action_update = emitter:newSignal()
    self.targeted_update = emitter:newSignal()
    self.p_defs_update = emitter:newSignal()
    self.cooldown_update = emitter:newSignal()
    self.disabled_clients_update = emitter:newSignal()

    --] Setup UI
    if is_client then
        self.prompt_ui = self.interact_gui:compile()

        self.prompt_ui:set_max_range(self.prompt_defs.range)
        self.prompt_ui:set_object(self.prompt_defs.object_name)
        self.prompt_ui:set_action(opts.action)
    end
    
    return self
end

--[[ prompt:trigger(instance: Instance, triggered_player: Player?)
    This will trigger the current prompt, running all connected functions
    and firing both "pre_trigger" and "triggered" signals.
    Also, if authorized, will inform the server of the trigger. ]]
function prompt:trigger(instance: Instance, triggered_player: Player?)
    local object_id, prompt_id = self.prompt_defs.object_id, self.prompt_id

    instance = instance or self.prompt_ui.target :: Instance
    if not instance then return end

    self.pre_trigger:fire(self, instance)

    if not self.active_cooldowns[instance] and self.attached_instances then
        self.active_cooldowns[instance] = {} end
    local inst_cooldowns = self.active_cooldowns[instance]

    if is_client then
        local finished, success = false, false --> Cache networking

        if inst_cooldowns['local'] then return end
        inst_cooldowns['local'] = true

        self.prompt_ui.update.set_cooldown(true)
        task.delay(self.cooldown, function()
            if finished and not success then
                return end
            inst_cooldowns['local'] = false
            self.prompt_ui.update.set_cooldown(false)
        end)

        self.prompt_ui.update.pre_trigger()
        if self.authorized then
            local fail_reason
            world_channel.interaction:with()
                :intent('trigger')
                :data(object_id, prompt_id, instance)
                :timeout(3)
                :invoke()
                    :andThen(function() success = true end)
                    :finally(function() finished = true end)
                    :catch(function(err)
                        warn(`An issue occured while triggering prompt! ({object_id}.{prompt_id})`)
                        if err[1] then
                            fail_reason = err[1]
                            warn(`A message was provided: {err[1]}`) end

                        inst_cooldowns['local'] = false
                        self.prompt_ui.update.set_cooldown(false)
                    end)

            repeat task.wait(0) until finished
            self.prompt_ui.update.triggered(success, fail_reason)
            self.triggered:fire(self, instance)

        end
    else
        if inst_cooldowns[triggered_player] then return false end
        if self.cooldown > 0 then
            inst_cooldowns[triggered_player] = true
            task.delay(self.cooldown, function()
                inst_cooldowns[triggered_player] = false
            end)
        end

        self.triggered:fire(self, instance, triggered_player)

        return true
    end
end

--[[ prompt:attach(Instance...)
    This will attach this prompt to an instance. ]]
function prompt:attach(...: Instance)
    local args = {...}
    for i, instance: Instance in pairs(args) do
        if table.find(self.attached_instances, instance) then
            warn(`[{script.Name}] prompt:attach() instance @ index {i} is already attached to this prompt!`)
            return end
        table.insert(self.attached_instances, instance)

        if is_client then
            self.prompt_ui:render(instance)
        end
    end

    if not is_client then
        world_channel.interaction:with()
            :broadcastGlobally()
            :intent('attach_instances')
            :data(self.prompt_defs.object_id, self.prompt_id, args)
            :fire()
    end
end

--[[ prompt:detach(Instance...)
    This will detach this prompt from an instance. ]]
function prompt:detach(...: Instance)
    local args = {...}
    for i, instance: Instance in pairs(args) do
        if not table.find(self.attached_instances, instance) then
            warn(`[{script.Name}] prompt:detach() instance @ index {i} is not attached to this prompt!`)
            return end
        table.remove(self.attached_instances, table.find(self.attached_instances, instance))
    
        if is_client then
            self.prompt_ui:unrender(instance)
        end
    end

    if not is_client then
        world_channel.interaction:with()
            :broadcastGlobally()
            :intent('detach_instances')
            :data(self.prompt_defs.object_id, self.prompt_id, args)
            :fire()
    else
    end
end

--[[ VISIBILITY ]]--

--[[ prompt:enable(instance: Instance)
    If the prompt is unrendered this will render it, and if it is it'll
    add the provided instance to the different targets it can append
    to. ]]
function prompt:enable(instance: Instance)
    self.enabled = true
    if is_client then
        if not instance then
            for _, instance in pairs(self.attached_instances) do
                self.prompt_ui:render(instance)
            end
        else
            self.prompt_ui:render(instance)
        end
    end
end

--[[ prompt:disable(instance: Instance)
    This will remove an appendable target from the prompt, and if none
    remain it'll be unrendered. ]]
function prompt:disable(instance: Instance)
    self.enabled = false
    if is_client then
        if not instance then
            for _, instance in pairs(self.attached_instances) do
                self.prompt_ui:unrender(instance)
            end
        else
            self.prompt_ui:unrender(instance)
        end
    end
end

--[[ DATA CONTROLS ]]--
--#region

--[[ prompt:setAction(new_action: string)
    Sets the action identifier & PromptUi field to new_action.
    Also signals "action_update" with the new action identifier. ]]
function prompt:setAction(new_action: string)
    assert(new_action, `attempt to :setAction() to nil!`)
    assert(type(new_action) == 'string', `attempt to :setAction() to an invalid type "{type(new_action)}"! (expected a string.)`)

    self.action = new_action
    self.action_update:fire(new_action)
    self.prompt_ui:set_action(new_action)
end

--[[ prompt:setTargeted(targeted: boolean)
    Sets the "targeted" status, which dictates if the prompt is visually
    selected, calling :set_targeted() to prompt_ui.
    Also signals "targeted_update" with the targeted state. ]]
function prompt:setTargeted(targeted: boolean)
    assert(targeted~=nil, `attempt to :setTargeted() to nil!`)
    assert(type(targeted) == 'boolean', `attempt to :setTargeted() to an invalid type "{type(targeted)}"! (expected a boolean.)`)

    self.targeted = targeted
    self.targeted_update:fire(targeted)
    self.prompt_ui:set_targeted(targeted)
end

--[[ prompt:setPromptDefs(new_defs: PromptDefs)
    Verifies the passed prompt_defs & updates the intenral PromptDefs to
    reflest the valid product.
    Also signals "p_defs_update" with the final valid PromptDefs. ]]
function prompt:setPromptDefs(new_defs: types._prompt_defs)
    assert(new_defs, `attempt to :setPromptDefs() to nil!`)
    assert(type(new_defs) == 'table', `attempt to :setPromptDefs() to a non-table!`)
    util.verify.prompt_defs(new_defs)
    
    self.prompt_defs = new_defs
    self.p_defs_update:fire(new_defs)
end

--[[ prompt:setCooldown(seconds: number)
    Sets the cooldown time to the passed "seconds" argument. This will
    be defaulted to 0 if nil.
    Also signals "cooldown_update" with the new cooldown time. ]]
function prompt:setCooldown(seconds: number)
    seconds = seconds or 0
    assert(type(seconds) == 'number', `attempt to :setCooldown() to an invalid type "{type(seconds)}"! (expected a number.)`)

    self.cooldown = seconds
    self.cooldown_update:fire(seconds)
end

--[[ prompt:disableForPlayers(...: Player)
    Adds player(s) to the visibility blacklist, making it so they can't
    see nor interact with the prompt.
    Also signals "disabled_clients_update" with the final disabled_clients
    list. ]]
function prompt:disableForPlayers(...: Player)
    local compiled = {...}
    local players = util.verify.player_table(compiled)

    for _, player in pairs(players) do
        self.disabled_clients[player] = true
    end
    self.disabled_clients_update:fire(self.disabled_clients)
end

--[[ prompt:enableForPlayers(...: Player)
    Removes player(s) to the visibility blacklist, granting them the
    ability to see and interact with the prompt.
    Also signals "disabled_clients_update" with the final disabled_clients
    list. ]]
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