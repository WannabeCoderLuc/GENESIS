--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local FirstStarStateV1 = require(script.Parent.FirstStarStateV1)

type Result<T> = Result.Result<T>

export type IgnitionSuccessV1 = {
	kind: "IgnitionSuccess",
	state: FirstStarStateV1.FirstStarStateV1,
}

export type FirstStarResultV1 = IgnitionSuccessV1

local FirstStarResultV1 = {}

function FirstStarResultV1.validate(raw: any): Result<FirstStarResultV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "FirstStarResultV1 must be a table")
	end
	
	if raw.kind == "IgnitionSuccess" then
		local stateResult = FirstStarStateV1.validate(raw.state)
		if not stateResult.ok then 
			return Result.err(ErrorCodes.SCHEMA_INVALID, "Invalid state: " .. stateResult.message) 
		end
		
		return Result.ok({
			kind = "IgnitionSuccess",
			state = stateResult.value,
		})
	end
	
	return Result.err(ErrorCodes.CMD_UNKNOWN_KIND, "Unknown FirstStarResult kind")
end

return table.freeze(FirstStarResultV1)
