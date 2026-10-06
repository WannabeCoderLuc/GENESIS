--!strict
local Result = require(game:GetService("ReplicatedStorage").Shared.Core.Result)
local ErrorCodes = require(game:GetService("ReplicatedStorage").Shared.Core.ErrorCodes)

type Result<T> = Result.Result<T>

export type Service = {
	name: string,
	init: ((self: Service) -> Result<boolean>)?,
	start: ((self: Service) -> Result<boolean>)?,
	stop: ((self: Service) -> Result<boolean>)?,
}

export type Lifecycle = {
	register: (self: Lifecycle, service: Service) -> (),
	initAll: (self: Lifecycle) -> Result<boolean>,
	startAll: (self: Lifecycle) -> Result<boolean>,
	stopAll: (self: Lifecycle) -> Result<boolean>,
}

local Lifecycle = {}
Lifecycle.__index = Lifecycle

function Lifecycle.new(): Lifecycle
	local self = setmetatable({
		_services = {} :: { Service },
		_state = "CREATED",
	}, Lifecycle)
	return self
end

function Lifecycle:register(service: Service)
	if self._state ~= "CREATED" then
		error("Cannot register service " .. service.name .. " after initialization")
	end
	table.insert(self._services, service)
end

function Lifecycle:initAll(): Result<boolean>
	if self._state ~= "CREATED" then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Lifecycle is not in CREATED state")
	end
	
	self._state = "INITIALIZING"
	for _, service in ipairs(self._services) do
		if service.init then
			local result = Result.protect(ErrorCodes.INTERNAL_ERROR, "init " .. service.name, function()
				return service:init()
			end)
			if not result.ok then return result end
			
			local inner = result.value
			if type(inner) == "table" and inner.ok == false then
				return inner
			end
		end
	end
	
	self._state = "INITIALIZED"
	return Result.ok(true)
end

function Lifecycle:startAll(): Result<boolean>
	if self._state ~= "INITIALIZED" then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Lifecycle is not in INITIALIZED state")
	end
	
	self._state = "STARTING"
	for _, service in ipairs(self._services) do
		if service.start then
			local result = Result.protect(ErrorCodes.INTERNAL_ERROR, "start " .. service.name, function()
				return service:start()
			end)
			if not result.ok then return result end

			local inner = result.value
			if type(inner) == "table" and inner.ok == false then
				return inner
			end
		end
	end
	
	self._state = "STARTED"
	return Result.ok(true)
end

function Lifecycle:stopAll(): Result<boolean>
	if self._state ~= "STARTED" and self._state ~= "STARTING" then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Lifecycle is not in STARTED state")
	end
	
	self._state = "STOPPING"
	for i = #self._services, 1, -1 do
		local service = self._services[i]
		if service.stop then
			local result = Result.protect(ErrorCodes.INTERNAL_ERROR, "stop " .. service.name, function()
				return service:stop()
			end)
			if not result.ok then return result end
			
			local inner = result.value
			if type(inner) == "table" and inner.ok == false then
				return inner
			end
		end
	end
	
	self._state = "STOPPED"
	return Result.ok(true)
end

return Lifecycle
