--!strict
--[[
	Paths: resolves modules under test from the DataModel. Specs go through here so a layout change touches one file.
	Tests run server-side (ServerStorage.Tests), where ReplicatedStorage.Shared and ServerScriptService.Server exist.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Paths = {}

local function child(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name)
	if found == nil then
		error(string.format("test path not found: %s.%s", parent:GetFullName(), name), 3)
	end
	return found
end

local function walk(root: Instance, segments: { string }): Instance
	local current = root
	for _, segment in ipairs(segments) do
		current = child(current, segment)
	end
	return current
end

-- Tests container (ServerStorage.Tests), derived from this module's location.
local testsRoot: Instance = (script.Parent :: Instance).Parent :: Instance

function Paths.shared(...: string): ModuleScript
	return walk(child(ReplicatedStorage, "Shared"), { ... }) :: ModuleScript
end

function Paths.core(name: string): ModuleScript
	return Paths.shared("Core", name)
end

function Paths.domain(name: string): ModuleScript
	return Paths.shared("Domain", name)
end

function Paths.contract(name: string): ModuleScript
	return Paths.shared("Contracts", name)
end

function Paths.server(...: string): ModuleScript
	return walk(child(ServerScriptService, "Server"), { ... }) :: ModuleScript
end

function Paths.vector(name: string): ModuleScript
	return walk(child(testsRoot, "Generated"), { "GoldenVectors", name }) :: ModuleScript
end

function Paths.support(name: string): ModuleScript
	return walk(testsRoot, { "Support", name }) :: ModuleScript
end

return Paths
