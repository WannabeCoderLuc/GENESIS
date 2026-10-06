--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.Shared.Core.Result)
local ErrorCodes = require(ReplicatedStorage.Shared.Core.ErrorCodes)

type Result<T> = Result.Result<T>

export type Migration = {
	fromVersion: number,
	toVersion: number,
	migrate: (raw: any) -> Result<any>,
}

export type MigrationHarness = {
	register: (self: MigrationHarness, migration: Migration) -> (),
	migrate: (self: MigrationHarness, raw: any, targetVersion: number) -> Result<any>,
}

local MigrationHarness = {}
MigrationHarness.__index = MigrationHarness

function MigrationHarness.new(): MigrationHarness
	local self = setmetatable({
		_migrations = {} :: { [number]: Migration },
	}, MigrationHarness)
	return self
end

function MigrationHarness:register(migration: Migration)
	self._migrations[migration.fromVersion] = migration
end

function MigrationHarness:migrate(raw: any, targetVersion: number): Result<any>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "Data must be a table to migrate")
	end

	local currentVersion = raw.schemaVersion or 0
	local currentData = raw

	while currentVersion < targetVersion do
		local migration = self._migrations[currentVersion]
		if not migration then
			return Result.err(
				ErrorCodes.SCHEMA_INVALID, 
				string.format("No migration found from version %d to %d", currentVersion, targetVersion)
			)
		end

		local result = migration.migrate(currentData)
		if not result.ok then
			return result
		end
		
		currentData = result.value
		currentVersion = migration.toVersion
		currentData.schemaVersion = currentVersion
	end

	return Result.ok(currentData)
end

return MigrationHarness
