--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Ids = require(script.Parent.Parent.Domain.Ids)
local Versions = require(script.Parent.Parent.Domain.Versions)

type Result<T> = Result.Result<T>

export type UniverseManifestV1 = {
	schemaVersion: Versions.SchemaVersion,
	universeId: Ids.UniverseId,
	ownerId: Ids.UserId,
	generatorVersion: Versions.GeneratorVersion,
	creationTime: number,
	seedHex: string,
}

local UniverseManifestV1 = {}

function UniverseManifestV1.validate(raw: any): Result<UniverseManifestV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "UniverseManifestV1 must be a table")
	end
	
	local schemaVersion = Versions.schemaVersion(raw.schemaVersion)
	if not schemaVersion.ok or schemaVersion.value ~= 1 then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "schemaVersion invalid")
	end
	
	local universeId = Ids.universeId(raw.universeId)
	if not universeId.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "universeId invalid") end
	
	local ownerId = Ids.userId(raw.ownerId)
	if not ownerId.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "ownerId invalid") end
	
	local genVersion = Versions.generatorVersion(raw.generatorVersion)
	if not genVersion.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "generatorVersion invalid") end
	
	if type(raw.creationTime) ~= "number" or raw.creationTime ~= raw.creationTime or math.abs(raw.creationTime) == math.huge then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "creationTime invalid")
	end
	
	if type(raw.seedHex) ~= "string" or not string.match(raw.seedHex, "^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$") then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "seedHex invalid")
	end

	return Result.ok({
		schemaVersion = schemaVersion.value,
		universeId = universeId.value,
		ownerId = ownerId.value,
		generatorVersion = genVersion.value,
		creationTime = raw.creationTime,
		seedHex = raw.seedHex,
	})
end

return UniverseManifestV1
