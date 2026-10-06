--!optimize 2
--!native
--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Settings = require("@game/ReplicatedStorage/Packages/Horus/Settings")
local Sera = require("@game/ReplicatedStorage/Packages/Horus/_Index/Sera")
local RemoteEventsServer = require("@self/RemoteEvents")
local RemoteFunctionsServer = require("@self/RemoteFunctions")
local SessionManager = require("@game/ReplicatedStorage/Packages/Horus/SessionManager")

local HorusServer = {}
local SharedHorus = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Horus")
HorusServer.Sera = Sera
HorusServer.RemoteEvents = RemoteEventsServer
HorusServer.RemoteFunctions = RemoteFunctionsServer
HorusServer.WaitForSession = function(self: any, player: Player?) return SessionManager:WaitForSession(player) end

local tracker = {
	Load = {} :: { [ModuleScript]: any },
	Init = {} :: { [ModuleScript]: boolean },
	Start = {} :: { [ModuleScript]: boolean },
}
local trackerForActors = {
	Load = {} :: { [ModuleScript]: Actor },
	Init = {},
	Start = {},
}

local started = false
local componentsStarted = false
local startFinished = false
local startFinishedBindable = Instance.new("BindableEvent")

local function newPrint(...: any)
	print("[S]", ...)
end
local function newWarn(...: any)
	warn("[S]", ...)
end

local function keepModule(container: Instance, module: ModuleScript): boolean
	if module:GetAttribute("ClientOnly") then return false end
	if module:GetAttribute("IgnoreLoader") then return false end

	local ancestor: Instance? = module.Parent
	while ancestor do
		if ancestor == container then return true end
		if not ancestor:IsA("Folder") then return false end
		ancestor = ancestor.Parent
	end
	return false
end

local function getModules(containers: { Instance }): { ModuleScript }
	local totalModules = {}
	local seenModules = {}

	for _, container in ipairs(containers) do
		for _, object in container:GetDescendants() do
			if object:IsA("ModuleScript") and not seenModules[object] and keepModule(container, object) then
				seenModules[object] = true
				table.insert(totalModules, object)
			end
		end
	end

	if Settings.USE_COLLECTION_SERVICE and Settings.LOADER_TAG ~= "" then
		for _, module in CollectionService:GetTagged(Settings.LOADER_TAG) do
			if module:IsA("Folder") then
				for _, child in module:GetDescendants() do
					if child:IsA("ModuleScript") and not seenModules[child] and keepModule(child.Parent, child) then
						seenModules[child] = true
						table.insert(totalModules, child)
					end
				end
			elseif module:IsA("ModuleScript") then
				if not seenModules[module] and keepModule(module.Parent, module) then
					seenModules[module] = true
					table.insert(totalModules, module)
				end
			end
		end
	end

	table.sort(totalModules, function(a, b)
		local aPriority = a:GetAttribute("LoaderPriority") :: number?
		local bPriority = b:GetAttribute("LoaderPriority") :: number?
		if aPriority and bPriority then
			return aPriority > bPriority
		elseif aPriority then
			return true
		end
		return false
	end)

	local RELOCATED_MODULES = ServerScriptService:FindFirstChild("RELOCATED_MODULES")
	if not RELOCATED_MODULES then
		RELOCATED_MODULES = Instance.new("Folder")
		RELOCATED_MODULES.Name = "RELOCATED_MODULES"
		RELOCATED_MODULES.Parent = ServerScriptService
	end

	for _, module in ipairs(totalModules) do
		if not module:GetAttribute("RelocateToServerScriptService") then
			continue
		end
		if module:IsDescendantOf(ServerScriptService) then
			continue
		end
		
		local clone = SharedHorus.RelocatedTemplate:Clone()
		clone.Name = module.Name
		clone:SetAttribute("ServerOnly", true)
		clone:SetAttribute("_RelocatedService", "ServerScriptService")
		clone:SetAttribute("_RelocatedPath", module.Name)
		clone.Parent = module.Parent
		module.Parent = RELOCATED_MODULES
	end

	return totalModules
end

local function loadModule(module: ModuleScript)
	if module:GetAttribute("Parallel") then
		local newActorSystem = script.Parent.ActorForServer:Clone()
		local actorScript = newActorSystem:FindFirstChildWhichIsA("BaseScript") :: BaseScript
		actorScript.Name = `Required{module.Name}`
		newActorSystem.Parent = ServerScriptService
		if not actorScript:GetAttribute("Loaded") then actorScript:GetAttributeChangedSignal("Loaded"):Wait() end
		newActorSystem:SendMessage("RequireModule", module)

		if Settings.VERBOSE_LOADING then newPrint((" | Loading PARALLEL module '%s'"):format(module.Name)) end
		local startTime = os.clock()
		if not actorScript:GetAttribute("Required") then actorScript:GetAttributeChangedSignal("Required"):Wait() end
		if Settings.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(` | Loaded PARALLEL module {module.Name}`, ("(took %.3f seconds)"):format(os.clock() - startTime))
		elseif actorScript:GetAttribute("Errored") then
			newWarn(` | Failed to load PARALLEL module {module.Name}`)
		end

		trackerForActors.Load[module] = newActorSystem
		tracker.Load[module] = true
		tracker.Init[module] = true
		tracker.Start[module] = true
		return
	end

	if Settings.VERBOSE_LOADING then newPrint((" | Loading module '%s'"):format(module.Name)) end
	local mainThread = coroutine.running()
	local startTime = os.clock()
	local endTime
	local executionSuccess, errMsg = false, ""
	local thread = task.spawn(function()
		debug.setmemorycategory(module.Name)
		local success, result = xpcall(function() return require(module) end, function(err) return `{err}\n{debug.traceback()}` end)
		if success then
			tracker.Load[module] = result
			if type(result) == "table" then
				if result.Init then tracker.Init[module] = false end
				if result.Start then tracker.Start[module] = false end
			end
			executionSuccess = true
		else
			errMsg = result
		end
		endTime = os.clock()
		if coroutine.status(mainThread) == "suspended" then task.spawn(mainThread) end
	end)
	if not endTime then endTime = os.clock() end
	if coroutine.status(thread) == "suspended" then
		local loopThread = task.spawn(function()
			task.wait(Settings.YIELD_THRESHOLD)
			while true do
				if coroutine.status(thread) == "suspended" then
					newWarn(` | Loading Module '{module.Name}' is taking a while! ({(os.clock() - startTime)}s)`)
				end
				task.wait(5)
			end
		end)
		coroutine.yield()
		if coroutine.status(loopThread) ~= "dead" then task.cancel(loopThread) end
	end
	
	if Settings.VERBOSE_LOADING and executionSuccess then
		newPrint(` | Loaded module {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
	elseif not executionSuccess then
		newWarn(` | Failed to load module {module.Name}\n{errMsg}`)
	end
end

local function initializeModule(loadedModule: any, module: ModuleScript)
	if trackerForActors.Load[module] then
		local actorScript: BaseScript = trackerForActors.Load[module]:FindFirstChildWhichIsA("BaseScript") :: any
		trackerForActors.Load[module]:SendMessage("InitModule")
		if Settings.VERBOSE_LOADING then newPrint(("〉 Initializing parallel module '%s'"):format(actorScript.Name)) end
		local startTime = os.clock()
		if not actorScript:GetAttribute("Initialized") then actorScript:GetAttributeChangedSignal("Initialized"):Wait() end
		if Settings.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(`〉 Initialized parallel module {actorScript.Name}`, ("(took %.3f seconds)"):format(os.clock() - startTime))
		end
		return
	end

	if type(loadedModule) ~= "table" or not loadedModule.Init then return end

	if Settings.VERBOSE_LOADING then newPrint((" | Initializing module '%s'"):format(module.Name)) end
	local mainThread = coroutine.running()
	local startTime = os.clock()
	local endTime
	local executionSuccess, errMsg = false, ""
	local thread = task.spawn(function()
		debug.setmemorycategory(module.Name)
		local success, err = xpcall(function() loadedModule:Init() end, function(err) return `{err}\n{debug.traceback()}` end)
		executionSuccess = success
		if success then
			tracker.Init[module] = true
		else
			errMsg = err
		end
		endTime = os.clock()
		if coroutine.status(mainThread) == "suspended" then task.spawn(mainThread) end
	end)
	if not endTime then endTime = os.clock() end
	if coroutine.status(thread) == "suspended" then
		local loopThread = task.spawn(function()
			task.wait(Settings.YIELD_THRESHOLD)
			while true do
				if coroutine.status(thread) == "suspended" then
					newWarn(` | :Init() for Module '{module.Name}' is taking a while!`)
				end
				task.wait(5)
			end
		end)
		coroutine.yield()
		if coroutine.status(loopThread) ~= "dead" then task.cancel(loopThread) end
	end
	
	if Settings.VERBOSE_LOADING and executionSuccess then
		newPrint(` | Initialized module {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
	elseif not executionSuccess then
		newWarn(` | Failed to init module {module.Name}\n{errMsg}`)
	end
end

local function startModule(loadedModule: any, module: ModuleScript)
	if trackerForActors.Load[module] then
		local actorScript: BaseScript = trackerForActors.Load[module]:FindFirstChildWhichIsA("BaseScript") :: any
		trackerForActors.Load[module]:SendMessage("StartModule")
		if Settings.VERBOSE_LOADING then newPrint((" | Starting PARALLEL module '%s'"):format(actorScript.Name)) end
		local startTime = os.clock()
		if not actorScript:GetAttribute("Started") then actorScript:GetAttributeChangedSignal("Started"):Wait() end
		if Settings.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(` | Started PARALLEL module {actorScript.Name}`, ("(took %.3f seconds)"):format(os.clock() - startTime))
		end
		return
	end

	if type(loadedModule) ~= "table" or not loadedModule.Start then return end

	if Settings.VERBOSE_LOADING then newPrint((" | Starting module '%s'"):format(module.Name)) end
	local mainThread = coroutine.running()
	local startTime = os.clock()
	local endTime
	local executionSuccess, errMsg = false, ""
	local thread = task.spawn(function()
		debug.setmemorycategory(module.Name)
		local success, err = xpcall(function() loadedModule:Start() end, function(err) return `{err}\n{debug.traceback()}` end)
		executionSuccess = success
		if success then
			tracker.Start[module] = true
		else
			errMsg = err
		end
		endTime = os.clock()
		if coroutine.status(mainThread) == "suspended" then task.spawn(mainThread) end
	end)
	if not endTime then endTime = os.clock() end
	if coroutine.status(thread) == "suspended" then
		local loopThread = task.spawn(function()
			task.wait(Settings.YIELD_THRESHOLD)
			while true do
				if coroutine.status(thread) == "suspended" then
					newWarn(` | :Start() for Module '{module.Name}' is taking a while!`)
				end
				task.wait(5)
			end
		end)
		coroutine.yield()
		if coroutine.status(loopThread) ~= "dead" then task.cancel(loopThread) end
	end

	if Settings.VERBOSE_LOADING and executionSuccess then
		newPrint(` | Started module {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
	elseif not executionSuccess then
		newWarn(` | Failed to start module {module.Name}\n{errMsg}`)
	end
end

function HorusServer:Start(...: Instance)
	assert(not started, "Attempt to start module loader more than once")
	started = true
	local containers = { ... }
	
	local modules = getModules(containers)
	
	if Settings.VERBOSE_LOADING then newWarn("〉 LOADING MODULES 〈") end
	for _, module in ipairs(modules) do loadModule(module) end
	
	if Settings.VERBOSE_LOADING then newWarn("〉 INITIALIZING MODULES 〈") end
	for _, module in ipairs(modules) do
		if tracker.Load[module] then initializeModule(tracker.Load[module], module) end
	end
	
	if Settings.VERBOSE_LOADING then newWarn("〉 STARTING MODULES 〈") end
	for _, module in ipairs(modules) do
		if tracker.Load[module] then startModule(tracker.Load[module], module) end
	end
	
	if Settings.VERBOSE_LOADING then newWarn("〉 LOADING FINISHED 〈") end
	
	SharedHorus:SetAttribute("ServerLoadedTimestamp", workspace:GetServerTimeNow())
	SharedHorus:SetAttribute("ServerLoaded", true)
	
	local loadedEvent = SharedHorus:FindFirstChild("LoadedEvent")
	if not loadedEvent then
		loadedEvent = Instance.new("RemoteEvent")
		loadedEvent.Name = "LoadedEvent"
		loadedEvent.Parent = SharedHorus
	end

	loadedEvent.OnServerEvent:Connect(function(player: Player)
		if not player:GetAttribute("ClientLoaded") then
			player:SetAttribute("ClientLoaded", true)
		end
	end)

	startFinished = true
	startFinishedBindable:Fire()
end

function HorusServer:StartComponents(...: Instance)
	assert(not componentsStarted, "attempt to start components more than once")
	componentsStarted = true
	local containers = { ... }
	if not startFinished then startFinishedBindable.Event:Wait() end
	
	local modules = getModules(containers)
	if Settings.VERBOSE_LOADING then newWarn("〉 LOADING COMPONENTS 〈") end
	for _, module in ipairs(modules) do loadModule(module) end
	if Settings.VERBOSE_LOADING then newWarn("〉 COMPONENTS LOADING FINISHED 〈") end
end

function HorusServer:GetRemoteEvent(serviceName: string, remoteName: string, schema: any)
	return RemoteEventsServer.new(remoteName, serviceName, schema)
end

function HorusServer:GetRemoteFunction(serviceName: string, remoteName: string, requestSchema: any, responseSchema: any)
	return RemoteFunctionsServer.new(remoteName, serviceName, requestSchema, responseSchema)
end

function HorusServer:IsServerLoaded(): boolean
	return SharedHorus:GetAttribute("ServerLoaded") == true
end

function HorusServer:IsClientLoaded(player: Player?): boolean
	return player and player:GetAttribute("ClientLoaded") == true or false
end

function HorusServer:IsPersistentLoaded(): boolean
	return true
end

function HorusServer:WaitForLoadedClient(player: Player): boolean
	if player:GetAttribute("ClientLoaded") then return true end

	local thread = coroutine.running()
	local connection
	local timeoutTask = task.delay(20, function()
		if connection then connection:Disconnect() end
		if player.Parent then
			player:Kick("Internal Timeout: Failed to load client in 20 seconds.")
		end
		coroutine.resume(thread, false)
	end)

	connection = player:GetAttributeChangedSignal("ClientLoaded"):Connect(function()
		if player:GetAttribute("ClientLoaded") then
			task.cancel(timeoutTask)
			connection:Disconnect()
			coroutine.resume(thread, true)
		end
	end)

	return coroutine.yield()
end

function HorusServer:GetServerLoadedTimestamp(): number
	return SharedHorus:GetAttribute("ServerLoadedTimestamp") or 0
end

return HorusServer
