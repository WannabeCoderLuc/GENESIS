--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)

type Result<T> = Result.Result<T>

export type IgnitionCommandV1 = {
	kind: "Ignition",
}

export type FirstStarCommandV1 = IgnitionCommandV1

local FirstStarCommandV1 = {}

function FirstStarCommandV1.validate(raw: any): Result<FirstStarCommandV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "FirstStarCommandV1 must be a table")
	end
	
	if raw.kind == "Ignition" then
		return Result.ok({
			kind = "Ignition",
		})
	end
	
	return Result.err(ErrorCodes.CMD_UNKNOWN_KIND, "Unknown FirstStarCommand kind")
end

return table.freeze(FirstStarCommandV1)
