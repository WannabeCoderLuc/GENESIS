--!nocheck
--[[
	StudioSync - Studio-side half of the repo -> Studio sync. Fetched over loopback HTTP by the stub in
	.agents/skills/universe-studio-test-run/SKILL.md and run through Studio MCP `execute_luau` (Edit datamodel).

	  install()          materialise the Rojo-mapped repo tree from the loopback manifest server
	  teardown()         remove everything install() created
	  runTests(options)  run the spec suite in ServerStorage.Tests (options: filter, timeoutSec)
	  status()           report whether a synced tree is present

	Safety:
	  * Creates only instances carrying attribute UCSync = true and removes only those, so the user's own content is
	    never touched. Engine-owned containers (services, StarterPlayerScripts) are reused, never replaced.
	  * Nothing is saved or published. HTTP is limited to http://127.0.0.1 (this machine).
]]

local HttpService = game:GetService("HttpService")

local HOST = "http://127.0.0.1:8765"
local MARK = "UCSync"
local SERVICES = { "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer", "Workspace" }

local StudioSync = {}

local function forEachMarkedTopLevel(callback: (Instance) -> ())
	for _, serviceName in ipairs(SERVICES) do
		for _, descendant in ipairs(game:GetService(serviceName):GetDescendants()) do
			local parent = descendant.Parent
			if parent ~= nil and descendant:GetAttribute(MARK) == true and parent:GetAttribute(MARK) ~= true then
				callback(descendant)
			end
		end
	end
end

function StudioSync.teardown()
	local removed = 0
	forEachMarkedTopLevel(function(instance)
		instance:Destroy()
		removed += 1
	end)
	local leftover = 0
	for _, serviceName in ipairs(SERVICES) do
		for _, descendant in ipairs(game:GetService(serviceName):GetDescendants()) do
			if descendant:GetAttribute(MARK) == true then
				leftover += 1
			end
		end
	end
	return { removedTopLevel = removed, leftoverMarked = leftover }
end

function StudioSync.status()
	local topLevel = 0
	forEachMarkedTopLevel(function()
		topLevel += 1
	end)
	return { syncedTopLevel = topLevel, isEdit = game:GetService("RunService"):IsEdit(), placeId = game.PlaceId, placeName = game.Name }
end

function StudioSync.install()
	local removedBefore = StudioSync.teardown().removedTopLevel

	local fetched, body = pcall(function()
		return HttpService:GetAsync(HOST .. "/manifest.json")
	end)
	if not fetched then
		return { ok = false, stage = "fetch", error = tostring(body) }
	end
	local decoded, manifest = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not decoded then
		return { ok = false, stage = "decode", error = tostring(manifest) }
	end

	local byPath = {}
	local created, reused, scripts = 0, 0, 0
	local errors = {}

	for _, entry in ipairs(manifest.entries) do
		local path, className = entry.p, entry.c
		local parentPath, name = string.match(path, "^(.*)/([^/]+)$")
		local instance
		if parentPath == nil then
			local gotService, service = pcall(function()
				return game:GetService(path)
			end)
			if gotService and service.ClassName == className then
				instance = service
				reused += 1
			else
				table.insert(errors, path .. ": service unavailable")
			end
		else
			local parent = byPath[parentPath]
			if parent == nil then
				table.insert(errors, path .. ": missing parent " .. parentPath)
			else
				local existing = parent:FindFirstChild(name)
				local engineOwned = existing ~= nil
					and existing.ClassName == className
					and existing:GetAttribute(MARK) ~= true
					and className ~= "Folder"
					and className ~= "ModuleScript"
				if engineOwned then
					instance = existing
					reused += 1
				else
					local made, newInstance = pcall(Instance.new, className)
					if not made then
						table.insert(errors, path .. ": cannot create " .. className)
					else
						newInstance.Name = name
						if entry.s ~= nil then
							newInstance.Source = entry.s
							scripts += 1
						end
						newInstance:SetAttribute(MARK, true)
						newInstance.Parent = parent
						instance = newInstance
						created += 1
					end
				end
			end
		end
		if instance ~= nil then
			byPath[path] = instance
		end
	end

	return {
		ok = #errors == 0,
		removedBefore = removedBefore,
		created = created,
		reused = reused,
		scripts = scripts,
		manifestSha256 = manifest.sha256,
		rojoVersion = manifest.rojoVersion,
		errors = errors,
	}
end

function StudioSync.runTests(options)
	local ServerStorage = game:GetService("ServerStorage")
	local testsRoot = ServerStorage:FindFirstChild("Tests")
	if testsRoot == nil then
		return { ok = false, error = "ServerStorage.Tests not found; run install() first" }
	end
	local Runner = require(testsRoot.Runner)
	local report = Runner.run(options or {})
	for _, failure in ipairs(report.failures) do
		if #failure.message > 700 then
			failure.message = string.sub(failure.message, 1, 700) .. "..."
		end
	end
	return report
end

return StudioSync
