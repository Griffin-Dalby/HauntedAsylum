--[[

    Entity Animator

    Griffin Dalby
    2025.09.16

    This module will provide an animator system for entities that will
    listen to state changes and dynamically provide the rig w/ animatons.

--]]

--]] Services
--]] Modules
local types = require(script.Parent.Parent.types)

--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Animator

local animator = {}
animator.__index = animator

function animator.new() : types.EntityAnimator
    local self = setmetatable({} :: types.self_animator, animator)

    self.animations = {}

    return self
end

function animator:defineAnimation(state: string, animation: Animation)
    assert(state, `:defineAnimation() state argument is undefined!`)
    assert(animation, `:defineAnimation() animation argument is undefined!`)

    assert(type(state) == 'string',
        `:defineAnimation() state argument is of type {type(state)}! It was expected to be a string.`)
    assert(typeof(animation) == 'Instance' and animation:IsA('Animation'),
        `:defineAnimation() animation argument isn't an Animation!`)

    self.animations[state] = animation
end

return animator