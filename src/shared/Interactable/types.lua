--[[

    Interactable Object Types

    Griffin Dalby
    2025.09.07

    This module will provide types for the Interactable Object.

--]]

local sawdust = require(game:GetService('ReplicatedStorage').Sawdust)
local signal = sawdust.core.signal

local types = {}

--[[ OPTIONS ]]--
--#region
export type _prompt_defs = {
    interact_gui: PromptUiBuilder?, --] What Builder to display for interactions
    interact_bind: { 
        desktop: Enum?,
        console: Enum?,
        mobile: Enum?
    }?, --] List of binds acceptable

    instance: {Instance}?, --] Custom instance target for specific prompt
    range: number,         --] Minimum distance you must be to activate
    raycast: boolean,      --] If true, the object instance must be in sight to interact.
    authorized: boolean,   --] If true, the client will contact the server to verify/parse interaction.

    hold_time: number?,    --] How long the bind must be held to activate, or 0 for tap.
}

export type _object_options = {
    object_id: string,
    object_name: string,

    authorized: boolean,
    instance: {Instance}?,
    prompt_defs: _prompt_defs?,
}

export type _prompt_options = {
    prompt_id: string,
    action: string,
    prompt_defs: _prompt_defs,

    cooldown: number?,
}

--#endregion

--[[ OBJECT ]]--
--#region
local object = {}
object.__index = object

export type _self_object = {
    object_id: string,
    object_name: string,

    instances: {Instance},
    prompt_defs: _prompt_defs?,

    prompts: {[string]: InteractablePrompt}
}
export type InteractableObject = typeof(setmetatable({} :: _self_object, object))

function object.new(opts: _object_options) : InteractableObject end

function object:newPrompt(opts: _prompt_options) : InteractablePrompt end

--#endregion

--[[ PROMPT UI & BUILDER ]]--
--#region

local prompt_ui = {}
prompt_ui.__index = prompt_ui

local prompt_builder = {}
prompt_builder.__index = prompt_builder

export type BuilderEnv = {
    root: Frame,

    object_name: string,
    action: string,
    targeted: boolean,
    binding: {code: Enum.KeyCode, type: Enum.UserInputType},

    on_cooldown: boolean,
    last_cooldown_tick: number,
}

export type _self_prompt_ui = {
    env: BuilderEnv,
    root_ui: Frame,
    orig_scale: UDim2,
    max_range: number,

    zindex: number,

    update: {
        object: (object_name: string) -> nil,
        action: (action: string) -> nil,
        targeted: (targeted: boolean) -> nil,
        binding: (code: Enum.KeyCode, type: Enum.UserInputType) -> nil,

        cooldown_change: ((on_cooldown: boolean) -> nil)?,
        cooldown_tick: ((time_remaining: number) -> nil)?,

        pre_trigger: () -> nil,
        triggered: (success: boolean, fail_reason: string) -> nil
    }
}
export type PromptUi = typeof(setmetatable({} :: _self_prompt_ui, prompt_ui))

function prompt_ui.new() : PromptUi end

function prompt_ui:render(target: BasePart) end
function prompt_ui:unrender() end

function prompt_ui:set_max_range(range: number) end

function prompt_ui:set_object(object_name: string) end
function prompt_ui:set_action(action: string) end
function prompt_ui:set_targeted(targeted: boolean) end
function prompt_ui:set_binding(key: Enum.KeyCode, type: Enum.UserInputType) end

function prompt_ui:set_cooldown(on_cooldown: boolean) end
function prompt_ui:cooldown_tick(time_remaining: number) end

export type _self_prompt_ui_builder = {
    root_ui: Frame,

    _on_compile: (() -> nil)?,

    _set_object: (env: BuilderEnv, object_name: string) -> nil,
    _set_action: (env: BuilderEnv, action: string) -> nil,
    _set_targeted: (env: BuilderEnv, targeted: boolean) -> nil,
    _set_binding: (env: BuilderEnv, code: Enum.KeyCode, type: Enum.UserInputType) -> nil,
    
    _pre_trigger: (env: BuilderEnv) -> nil,
    _triggered: (env: BuilderEnv, success: boolean, fail_reason: string) -> nil,

    _no_cooldown: boolean?,
    _set_cooldown: ((env: BuilderEnv, on_cooldown: boolean) -> nil)?,
    _update_cooldown: ((env: BuilderEnv, time_remaining: number) -> nil?),
}
export type PromptUiBuilder = typeof(setmetatable({} :: _self_prompt_ui_builder, prompt_builder))

function prompt_builder.new() : PromptUiBuilder end

function prompt_builder:set_object(handler:  (env: BuilderEnv, object_name: string) -> nil): PromptUiBuilder end
function prompt_builder:set_action(handler:  (env: BuilderEnv, action: string)      -> nil): PromptUiBuilder end
function prompt_builder:set_targeted(handler: (env: BuilderEnv, targeted: boolean)  -> nil): PromptUiBuilder end
function prompt_builder:set_binding(handler: (env: BuilderEnv, code: Enum.KeyCode, type: Enum.UserInputType) -> nil): PromptUiBuilder end

function prompt_builder:pre_trigger(handler: (env: BuilderEnv) -> nil): PromptUiBuilder end
function prompt_builder:triggered(handler: (env: BuilderEnv, success: boolean, fail_reason: string) -> nil): PromptUiBuilder end

function prompt_builder:no_cooldown(): PromptUiBuilder end
function prompt_builder:set_cooldown(handler:    (env: BuilderEnv, on_cooldown: boolean) -> nil) : PromptUiBuilder end
function prompt_builder:update_cooldown(handler: (env: BuilderEnv, time_remaining: number) -> nil) : PromptUiBuilder end

function prompt_builder:compile() : PromptUi end

--#endregion

--[[ PROMPT ]]--
--#region
local prompt = {}
prompt.__index = prompt

export type _self_prompt = {
    prompt_id: string, --] ID for this prompt
    action: string, --] Action for this Prompt
    prompt_defs: _prompt_defs,
    prompt_ui: PromptUi?,

    attached_instances: { Instance }, --] List of instances this prompt appears for

    cooldown: number,    --] Length of cooldown between each trigger
    authorized: boolean, --] If the server needs to verify/parse action

    disabled_clients: {}, --] Which clients cannot see/trigger this prompt
    enabled: boolean,

    --] Signals
    pre_trigger: signal.SawdustSignal, --] Fired whenever this prompt is triggered, before authorization.
    triggered: signal.SawdustSignal,   --] Fired whenever this prompt is triggered, after authorization.

    action_update: signal.SawdustSignal,   --] Fired whenever "action" is updated.
    targeted_update: signal.SawdustSignal, --] Fired whenever "targeted" is updated.
    p_defs_update: signal.SawdustSignal,   --] Fired whenever "prompt_defs" is updated.
    cooldown_update: signal.SawdustSignal, --] Fired whenever "cooldown" is updated.
    disabled_clients_update: signal.SawdustSignal, --] Fired whenever "disabled_clients" is updated.

}
export type InteractablePrompt = typeof(setmetatable({} :: _self_prompt, prompt))

function prompt.new(opts: _prompt_options): InteractablePrompt end

function prompt:trigger(instance: Instance, triggered_player: Player) end
function prompt:attach(...: Instance) end
function prompt:detach(...: Instance) end

function prompt:enable(instance: Instance) end
function prompt:disable(instance: Instance) end

function prompt:setAction(new_action: string) end
function prompt:setTargeted(targeted: boolean) end
function prompt:setPromptDefs(new_defs: _prompt_defs) end
function prompt:setCooldown(seconds: number) end

function prompt:disableForPlayers(...: Player) end
function prompt:enableForPlayer(...: Player) end

function prompt:destroy() end

--#endregion

--[[ PLATFORM ]]--
--#region
local platform = {}
platform.__index = platform

export type _self_platform = {
    platform: 'desktop'|'console'|'mobile',
    brand: 'generic'|'xbox'|'ps'|'switch'
}
export type PlatformMap = typeof(setmetatable({} :: _self_platform, platform))

function platform.new() : PlatformMap end

--#endregion

--[[ NET EVENT ]]--
--#region
local netEvent = {}
netEvent.__index = netEvent

export type _self_net_event = {}
export type NetEvent = typeof(setmetatable({} :: _self_net_event, netEvent))

function netEvent.new() : NetEvent end

--#endregion

return types