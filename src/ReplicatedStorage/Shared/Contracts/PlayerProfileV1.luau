--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Ids = require(script.Parent.Parent.Domain.Ids)
local Versions = require(script.Parent.Parent.Domain.Versions)

type Result<T> = Result.Result<T>

export type PlayerProfileV1 = {
	schemaVersion: Versions.SchemaVersion,
	userId: Ids.UserId,
	creationTime: number,
	lastSaveTime: number,
}

local PlayerProfileV1 = {}

function PlayerProfileV1.validate(raw: any): Result<PlayerProfileV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "PlayerProfileV1 must be a table")
	end
	
	local schemaVersion = Versions.schemaVersion(raw.schemaVersion)
	if not schemaVersion.ok or schemaVersion.value ~= 1 then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "schemaVersion invalid")
	end
	
	local userId = Ids.userId(raw.userId)
	if not userId.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "userId invalid") end
	
	if type(raw.creationTime) ~= "number" or raw.creationTime ~= raw.creationTime or math.abs(raw.creationTime) == math.huge then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "creationTime invalid")
	end
	
	if type(raw.lastSaveTime) ~= "number" or raw.lastSaveTime ~= raw.lastSaveTime or math.abs(raw.lastSaveTime) == math.huge then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "lastSaveTime invalid")
	end
	
	return Result.ok({
		schemaVersion = schemaVersion.value,
		userId = userId.value,
		creationTime = raw.creationTime,
		lastSaveTime = raw.lastSaveTime,
	})
end

return PlayerProfileV1
