--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Ids = require(script.Parent.Parent.Domain.Ids)
local Versions = require(script.Parent.Parent.Domain.Versions)
local BoundedSchemaValidator = require(script.Parent.BoundedSchemaValidator)

type Result<T> = Result.Result<T>

export type CommandEnvelopeV1 = {
	schemaVersion: Versions.SchemaVersion,
	commandId: Ids.CommandId,
	universeId: Ids.UniverseId?,
	kind: string,
	payload: any,
	timestamp: number,
}

local CommandEnvelopeV1 = {}

function CommandEnvelopeV1.validate(raw: any): Result<CommandEnvelopeV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "CommandEnvelopeV1 must be a table")
	end
	
	local schemaVersion = Versions.schemaVersion(raw.schemaVersion)
	if not schemaVersion.ok or schemaVersion.value ~= 1 then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "schemaVersion invalid")
	end
	
	local commandId = Ids.commandId(raw.commandId)
	if not commandId.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "commandId invalid") end
	
	local universeIdVal = nil
	if raw.universeId ~= nil then
		local uid = Ids.universeId(raw.universeId)
		if not uid.ok then return Result.err(ErrorCodes.SCHEMA_INVALID, "universeId invalid") end
		universeIdVal = uid.value
	end
	
	if type(raw.kind) ~= "string" or #raw.kind == 0 or #raw.kind > 64 then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "kind invalid")
	end
	
	if raw.payload == nil then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "payload missing")
	end
	
	if type(raw.timestamp) ~= "number" or raw.timestamp ~= raw.timestamp or math.abs(raw.timestamp) == math.huge then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "timestamp invalid")
	end

	local limitsCheck = BoundedSchemaValidator.checkLimits(raw.payload, {
		maxDepth = 16,
		maxNodes = 1024,
		maxStringBytes = 4096,
	})
	if not limitsCheck.ok then
		return Result.err(ErrorCodes.SCHEMA_LIMIT_EXCEEDED, limitsCheck.message)
	end

	return Result.ok({
		schemaVersion = schemaVersion.value,
		commandId = commandId.value,
		universeId = universeIdVal,
		kind = raw.kind,
		payload = raw.payload,
		timestamp = raw.timestamp,
	})
end

return CommandEnvelopeV1
