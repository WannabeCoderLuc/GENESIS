--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.Shared.Core.Result)

type Result<T> = Result.Result<T>

export type PersistenceRepository = {
	get: (self: PersistenceRepository, key: string) -> Result<any>,
	set: (self: PersistenceRepository, key: string, value: any) -> Result<boolean>,
	update: (self: PersistenceRepository, key: string, transform: (any) -> any) -> Result<any>,
	delete: (self: PersistenceRepository, key: string) -> Result<boolean>,
}

local InMemoryRepository = {}
InMemoryRepository.__index = InMemoryRepository

function InMemoryRepository.new(): PersistenceRepository
	local self = setmetatable({
		_store = {} :: { [string]: any },
	}, InMemoryRepository)
	return self
end

function InMemoryRepository:get(key: string): Result<any>
	return Result.ok(self._store[key])
end

function InMemoryRepository:set(key: string, value: any): Result<boolean>
	self._store[key] = value
	return Result.ok(true)
end

function InMemoryRepository:update(key: string, transform: (any) -> any): Result<any>
	local current = self._store[key]
	local new = transform(current)
	self._store[key] = new
	return Result.ok(new)
end

function InMemoryRepository:delete(key: string): Result<boolean>
	if self._store[key] ~= nil then
		self._store[key] = nil
		return Result.ok(true)
	end
	return Result.ok(false)
end

return InMemoryRepository
