--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Versions = require(script.Parent.Parent.Domain.Versions)

type Result<T> = Result.Result<T>

export type SpectralClass = "O" | "B" | "A" | "F" | "G" | "K" | "M"

export type FirstStarStateV1 = {
	schemaVersion: Versions.SchemaVersion,
	mass: number,
	temperature: number,
	spectralClass: SpectralClass,
	luminosity: number,
	radius: number,
	age: number,
	lifespan: number,
	ignitedAt: number,
}

local FirstStarStateV1 = {}

local VALID_CLASSES = {
	O = true, B = true, A = true, F = true, G = true, K = true, M = true
}

function FirstStarStateV1.validate(raw: any): Result<FirstStarStateV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "FirstStarStateV1 must be a table")
	end
	
	local schemaVersion = Versions.schemaVersion(raw.schemaVersion)
	if not schemaVersion.ok or schemaVersion.value ~= 1 then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "schemaVersion invalid")
	end
	
	if type(raw.mass) ~= "number" or raw.mass ~= raw.mass then return Result.err(ErrorCodes.SCHEMA_INVALID, "mass invalid") end
	if type(raw.temperature) ~= "number" or raw.temperature ~= raw.temperature then return Result.err(ErrorCodes.SCHEMA_INVALID, "temperature invalid") end
	
	if type(raw.spectralClass) ~= "string" or not VALID_CLASSES[raw.spectralClass] then 
		return Result.err(ErrorCodes.SCHEMA_INVALID, "spectralClass invalid") 
	end
	
	if type(raw.luminosity) ~= "number" or raw.luminosity ~= raw.luminosity then return Result.err(ErrorCodes.SCHEMA_INVALID, "luminosity invalid") end
	if type(raw.radius) ~= "number" or raw.radius ~= raw.radius then return Result.err(ErrorCodes.SCHEMA_INVALID, "radius invalid") end
	if type(raw.age) ~= "number" or raw.age ~= raw.age then return Result.err(ErrorCodes.SCHEMA_INVALID, "age invalid") end
	if type(raw.lifespan) ~= "number" or raw.lifespan ~= raw.lifespan then return Result.err(ErrorCodes.SCHEMA_INVALID, "lifespan invalid") end
	if type(raw.ignitedAt) ~= "number" or raw.ignitedAt ~= raw.ignitedAt then return Result.err(ErrorCodes.SCHEMA_INVALID, "ignitedAt invalid") end
	
	return Result.ok({
		schemaVersion = schemaVersion.value,
		mass = raw.mass,
		temperature = raw.temperature,
		spectralClass = raw.spectralClass :: SpectralClass,
		luminosity = raw.luminosity,
		radius = raw.radius,
		age = raw.age,
		lifespan = raw.lifespan,
		ignitedAt = raw.ignitedAt,
	})
end

return table.freeze(FirstStarStateV1)
