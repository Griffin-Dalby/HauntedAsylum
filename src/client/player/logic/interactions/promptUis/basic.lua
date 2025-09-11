--[[

    Basic PromptUI

    Griffin Dalby
    2025.09.10

    This module provides a example of a PromptUI.

--]]

local replicatedStorage = game:GetService('ReplicatedStorage')
local interactable = require(replicatedStorage.Shared.Interactable)

return function ()
    local base_ui = game:GetService('StarterGui').UI.Interaction2 :: Frame
    local p_ui = interactable.newPromptUiBuilder(base_ui, 'basic')
        :set_object(function(env, object_name)
            env.root.object_name.Text = object_name
        end)
        :set_action(function(env, action)
            env.root.action_string.Text = action
        end)
        :set_targeted(function(env, targeted)
            env.root.object_name.TextColor3 = targeted
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(100, 100, 100)
            env.root.object_name.TextTransparency = targeted
                and 0 or .5

            env.root.action_string.TextColor3 = targeted
                and Color3.fromRGB(255, 255, 255)
                or Color3.fromRGB(100, 100, 100)
            env.root.object_name.TextTransparency = targeted
                and 0 or .5

            env.root.bind.ImageTransparency = targeted
                and .25 or .75
            env.root.bind.Label.TextTransparency = targeted
                and 0 or .75

        end)
        :set_binding(function(env, code, type)
            env.root.bind.Label.Text = code.Name
        end)

        :pre_trigger(function(env)
            --> Triggered (before server auth)
        end)
        :triggered(function(env, success, fail_reason)
            --> Triggered (after server auth)
        end)

        :set_cooldown(function(env, on_cooldown)
            env.root.bind.BackgroundColor3 = on_cooldown and Color3.fromRGB(45, 45, 45) or Color3.fromRGB(75, 75, 75)
            if not on_cooldown then
                env.root.bind.Label.Text = env.binding.code.Name
            end
        end)
        :update_cooldown(function(env, time_remaining)
            env.root.bind.Text = tostring(time_remaining)
        end)

    return p_ui
end