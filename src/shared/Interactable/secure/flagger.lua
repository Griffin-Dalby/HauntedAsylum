--[[

    Secure Player Flagger

    Griffin Dalby
    2025.09.09

    This module provides logic to switch different flags on a player,
    built from a template.

--]]

--]] Services
--]] Modules
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Module
local flagger = {}
flagger.__index = flagger

type self = {
    _template: {[string]: boolean,},
    flags: {[string]: boolean,},

    children: {[string]: Flagger,},
}
export type Flagger = typeof(setmetatable({} :: self, flagger))

--[[ flagger.new() : Flagger
    This will return a new Flagger, which will generate
    values from a provided template, and make it easy to switch tags
    and generalize if a player is "okay"]]
function flagger.new(template: {}) : Flagger
    local self = setmetatable({} :: self, flagger)

    self._template = {}
    self.flags = {}
    for i, v in pairs(template) do
        self.flags[i] = v
        self._template[i] = v end --> Copy to flags & template

    self.children = {}

    return self
end

--]] FLAGS
--#region

--[[ flagger:setFlag(flag_id: string, state: boolean)
    This will set a specific flag to *state. ]]
function flagger:setFlag(flag_id: string, state: boolean)
    assert(flag_id, `:setFlag() Argument #1 (flag_id) is nil!`)
    assert(state~=nil, `:setFlag() Argument #2 (state) is nil!`)
    assert(self.flags[flag_id]~=nil, `Couldn't find flag w/ ID "{flag_id}"! Check the provided template.`)

    self.flags[flag_id] = state
end

--[[ flagger:getFlag(flag_id: string): boolean
    This will locate and return the state of a specific flag. ]]
function flagger:getFlag(flag_id: string): boolean
    assert(flag_id~=nil, `:getFlag() Argument #1 (flag_id) is nil!`)
    assert(self.flags[flag_id]~=nil, `Couldn't find flag w/ ID "{flag_id}"! Check the provided template.`)

    return self.flags[flag_id]
end
--#endregion

--]] SUB-FLAGGERS
--#region

--[[ flagger:newChild(name: string, template: {}) : Flagger
    Creates a new Flagger in a table as a child to this layer.
    
    If the template argument isn't passed, the parent's template
    will be used.]]
function flagger:newChild(name: string, template: {}) : Flagger
    assert(name, `Attempt to create a new child without passing a name!`)
    assert(self.children[name]==nil, `There's already a child with the name "{name}" under this flagger!`)
    
    local sub_flagger = flagger.new(template or self._template)
    self.children[name] = sub_flagger
    return sub_flagger
end

--[[ flagger:findChild(name: string) : Flagger
    Attempts to locate a child with a specific name under this flagger. ]]
function flagger:findChild(name: string) : Flagger
    assert(name, `Attempt to find a child without passing a name!`)
    assert(self.children[name]~=nil, `Failed to find child with the name "{name}" under this flagger.`)

    return self.children[name]
end

--[[ flagger:hasChild(name: string) : boolean
    Returns the status of existence for a child with the provided name
    under this flagger. ]]
function flagger:hasChild(name: string) : boolean
    assert(name, `Attempt to check for existence of child without passing a name!`)

    return self.children[name] ~= nil
end

--#endregion

--[[ flagger:isClean(): boolean
    Returns true if all flags are false. ]]
function flagger:isClean(): boolean
    local is_clean = true

    local function check_tbl(t: {})
        for i, v in pairs(t.flags) do
            if v==true then
                is_clean = false
                break end
        end

        for _, child in pairs(t.children) do
            check_tbl(child)
        end
    end

    check_tbl(self)
    

    return is_clean
end

--[[ flagger:destroy()
    Cleans up this flagger. ]]
function flagger:destroy()
    table.clear(self.flags)
    table.clear(self)
end

return flagger