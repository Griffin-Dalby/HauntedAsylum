--[[

    Sawdust Service Controller

    Griffin Dalby
    2025.10.15

    This script will resolve & start all Sawdust Services for the
    server.

--]]

--]] Services
local replicatedStorage = game:GetService('ReplicatedStorage')

--]] Modules
--]] Sawdust
local sawdust = require(replicatedStorage.Sawdust)
local services = sawdust.services

for _, service: ModuleScript in pairs(script.Services:GetChildren()) do
    if not service:IsA('ModuleScript') then
        if service.Name:sub(1,2)~='__' then
            warn(`[{script.Name}] Found invalid ServiceModule @ {service:GetFullName()}!`) end
        continue
    end

    local this_service = require(service)
    services:register(this_service)
end

services:resolveAll()
services:startAll()