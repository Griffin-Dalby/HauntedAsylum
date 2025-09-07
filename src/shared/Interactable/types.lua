--[[

    Interactable Object Types

    Griffin Dalby
    2025.09.07

    This module will provide types for the Interactable Object.

--]]

local types = {}

--[[ OPTIONS ]]--
--#region
export type _prompt_defs = {
    interact_gui: Instance?,                               --] What UI to display for interactions
    interact_bind: { Enum.KeyCode | Enum.UserInputType }?, --] List of binds acceptable

    range: number,      --] Minimum distance you must be to activate
    raycast: boolean,   --] If true, the object instance must be in sight to interact.

    hold_time: number?, --] How long the bind must be held to activate, or 0 for tap.
}

export type _object_options = {
    object_name: string,
    instance: Instance,
    prompt_defs: _prompt_defs?,
}

--#endregion

--[[ OBJECT ]]--
--#region
local object = {}
object.__index = object

export type _self_object = {}
export type InteractableObject = typeof(setmetatable({} :: _self_object, object))

function object.new(opts: _object_options) : InteractableObject; end

--#endregion

--[[ PROMPT ]]--
--#region
local prompt = {}
prompt.__index = prompt

export type _self_prompt = {}
export type InteractablePrompt = typeof(setmetatable({} :: _self_prompt, prompt))

function prompt.new(): InteractablePrompt; end

--#endregion

return types