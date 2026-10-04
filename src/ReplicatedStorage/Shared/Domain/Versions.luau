--!strict
--[[
	Versions: strict version types.

	- SchemaVersion    versions a persisted/wire data shape (PlayerProfileV1 -> 1). Changes require a migration.
	- GeneratorVersion versions a procedural-generator family. It is hashed into every derived seed, so changing
	                   it intentionally changes generated output (see 08-PROCEDURAL-GENERATION.md).
	- RulesetVersion   versions gameplay balance rules. A generator upgrade is not a schema migration.
	- BuildVersion     identifies the deployed code (major.minor.patch+id) for observability and rollbacks.

	Authority: shared, pure.
]]

local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Result = require(script.Parent.Parent.Core.Result)

type Result<T> = Result.Result<T>

export type SchemaVersion = number & { __brand: "SchemaVersion" }
export type GeneratorVersion = number & { __brand: "GeneratorVersion" }
export type RulesetVersion = number & { __brand: "RulesetVersion" }
export type BuildVersion = { major: number, minor: number, patch: number, id: string }

local MAX_VERSION = 2147483647

local Versions = {}

-- Version currently produced by this build for each persisted/generated family.
Versions.CURRENT_GENERATOR_VERSION = (1 :: any) :: GeneratorVersion
Versions.CURRENT_RULESET_VERSION = (1 :: any) :: RulesetVersion
Versions.BUILD = { major = 0, minor = 1, patch = 0, id = "phase0.dev" } :: BuildVersion

local function parsePositiveInteger(raw: unknown, label: string): Result<number>
	if type(raw) ~= "number" or raw ~= raw or raw < 1 or raw > MAX_VERSION or raw ~= math.floor(raw) then
		return Result.err(ErrorCodes.VERSION_INVALID, label .. " must be an integer in [1, 2147483647]")
	end
	return Result.ok(raw)
end

function Versions.schemaVersion(raw: unknown): Result<SchemaVersion>
	return parsePositiveInteger(raw, "SchemaVersion") :: any
end

function Versions.generatorVersion(raw: unknown): Result<GeneratorVersion>
	return parsePositiveInteger(raw, "GeneratorVersion") :: any
end

function Versions.rulesetVersion(raw: unknown): Result<RulesetVersion>
	return parsePositiveInteger(raw, "RulesetVersion") :: any
end

-- Parses "major.minor.patch+id" (id: 1-32 chars of [A-Za-z0-9._-]).
function Versions.parseBuild(text: string): Result<BuildVersion>
	local major, minor, patch, id = string.match(text, "^(%d+)%.(%d+)%.(%d+)%+([A-Za-z0-9._%-]+)$")
	if major == nil or id == nil or #id > 32 then
		return Result.err(ErrorCodes.VERSION_INVALID, "BuildVersion must look like 1.2.3+id")
	end
	local majorNumber, minorNumber, patchNumber = tonumber(major), tonumber(minor), tonumber(patch)
	if majorNumber == nil or minorNumber == nil or patchNumber == nil then
		return Result.err(ErrorCodes.VERSION_INVALID, "BuildVersion numeric parts invalid")
	end
	if majorNumber > 9999 or minorNumber > 9999 or patchNumber > 9999 then
		return Result.err(ErrorCodes.VERSION_INVALID, "BuildVersion numeric parts must be <= 9999")
	end
	return Result.ok({ major = majorNumber, minor = minorNumber, patch = patchNumber, id = id })
end

function Versions.formatBuild(build: BuildVersion): string
	return string.format("%d.%d.%d+%s", build.major, build.minor, build.patch, build.id)
end

return Versions
