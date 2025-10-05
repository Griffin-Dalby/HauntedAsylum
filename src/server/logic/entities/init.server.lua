--[[

    Server Entity Logic

    Griffin Dalby
    2025.09.09

    This script will search the meta folder and spawn entities off of the data
    found.

--]]

--]] Services
--]] Modules
--]] Sawdust
--]] Settings
--]] Constants
--]] Variables
--]] Functions
--]] Logic

--> Setup entities
for _, entity_data: ModuleScript in pairs(script.meta:GetChildren()) do
    if not entity_data:IsA('ModuleScript') then continue end
    local generator = require(entity_data) --]] TODO: Possibly just access the meta and build it here?

    generator()
end