--[[

    Interactable Prompt Builder

    Griffin Dalby
    2025.09.08

    This module will take in a UI and pointers to create an interactable
    prompt usable across the entire interaction system.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.Parent.types)
local promptUi = require(script.Parent.promptUi)

--]] Settings
--]] Constants
--]] Variables
--]] Functions
function wrap_f(env_id, handler)
    return function(env, ...)
        local args = {...}
        env[env_id] = args[1]

        handler(env, unpack(args))
    end
end

--]] Modules
--]] Builder
local builder = {}
builder.__index = builder

function builder.new(root_ui: Frame) : types.PromptUiBuilder
    assert(root_ui, `attempt to create a new promptBuilder with a nil root_ui!`)

    local self = setmetatable({} :: types._self_prompt_ui_builder, builder)

    self.root_ui = root_ui

    return self
end

function builder:set_object(handler: (env: types.BuilderEnv, object_name: string) -> nil) : types.PromptUiBuilder
    self._set_object = wrap_f('object_name', handler)
    return self end
function builder:set_action(handler: (env: types.BuilderEnv, action: string) -> nil) : types.PromptUiBuilder
    self._set_action = wrap_f('action', handler)
    return self end
function builder:set_targeted(handler: (env: types.BuilderEnv, targeted: boolean) -> nil) : types.PromptUiBuilder
    self._set_targeted = wrap_f('targeted', handler)
    return self end
function builder:set_binding(handler: (env: types.BuilderEnv, code: Enum.KeyCode, type: Enum.UserInputType) -> nil) : types.PromptUiBuilder
    self._set_binding = wrap_f('binding', handler)
    return self end

function builder:no_cooldown() : types.PromptUiBuilder
    self._no_cooldown = true
    return self end
function builder:set_cooldown(handler: (env: types.BuilderEnv, on_cooldown: boolean) -> nil) : types.PromptUiBuilder
    self._set_cooldown = wrap_f('on_cooldown', handler)
    return self end
function builder:update_cooldown(handler: (env: types.BuilderEnv, time_remaining: number) -> nil) : types.PromptUiBuilder
    self._update_cooldown = wrap_f('last_cooldown_tick', handler)
    return self end

function builder:compile() : types.PromptUi
    assert(self._set_object, `You need to :set_object(f(object_name: string)), and change your ui's name text!`)
    assert(self._set_action, `You need to :set_action(f(action: string)), and change your ui's action text!`)
    assert(self._set_binding, `You need to :set_binding(f(code: Keycode, type: UserInputType)), and change your ui's binding text!`)

    if not self._no_cooldown then
        assert(self._set_cooldown, `You need to :set_cooldown(f(on_cooldown: boolean)), and change your ui accordingly (or disable cooldown behavior with :no_cooldown())`)
        assert(self._update_cooldown, `You need to :update_cooldown(f(time_remaining: number)), and change your ui accordingly (or disable cooldown behavior with :no_cooldown())`)
    end

    return promptUi.new(self)
end

return builder