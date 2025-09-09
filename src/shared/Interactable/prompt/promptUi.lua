--[[

    PromptUI Object

    Griffin Dalby
    2025.09.08

    This module will provide a PromptUi instance that can be cloned
    and destroyed.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local promptUi = {}
promptUi.__index = promptUi

function promptUi.new(builder_data: types.PromptUiBuilder) : types.PromptUi
    local self = setmetatable({} :: types._self_prompt_ui, promptUi)

    --]] Construct Data
    self.root_ui = builder_data.root_ui:Clone()

    self.env = {}
    self.env.root = self.root_ui

    local function wrap_f(handler)
        return function(...)
            handler(self.env, ...)
        end
    end

    self.update = {
        object  = wrap_f(builder_data._set_object),
        action  = wrap_f(builder_data._set_action),
        binding = wrap_f(builder_data._set_binding),
        
        set_cooldown  = builder_data._no_cooldown
            and nil or wrap_f(builder_data._set_cooldown),
        cooldown_tick = builder_data._no_cooldown
            and nil or wrap_f(builder_data._update_cooldown),
    }

    return self
end

function promptUi:set_object(object_name: string)
    self.update.object(object_name) end
function promptUi:set_action(action: string)
    self.update.action(action) end
function promptUi:set_binding(key: Enum.KeyCode, type: Enum.UserInputType)
    self.update.binding(key, type) end

function promptUi:set_cooldown(on_cooldown: boolean)
    self.update.set_cooldown(on_cooldown) end
function promptUi:cooldown_tick(time_remaining: number)
    self.update.cooldown_tick(time_remaining) end

return promptUi