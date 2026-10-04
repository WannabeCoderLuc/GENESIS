--!strict
--[[
	Ids: branded identifier types and their only constructors.

	Brands are compile-time only (runtime values are plain strings/numbers). The sole way to obtain a branded ID
	from untrusted input is a constructor here, so an unvalidated string cannot be passed where a UniverseId is
	expected without an explicit `:: any` cast (which lint-policy flags outside tests).

	Stable ID grammar: 1-64 bytes of [A-Za-z0-9_.-]. ':' and '/' are excluded so canonical address text
	("epoch:E1/cluster:C2") is unambiguous. Matching is by explicit byte ranges, never locale-sensitive patterns.

	Authority: shared, pure.
]]

local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Result = require(script.Parent.Parent.Core.Result)

type Result<T> = Result.Result<T>

export type UserId = number & { __brand: "UserId" }
export type UniverseId = string & { __brand: "UniverseId" }
export type EpochId = string & { __brand: "EpochId" }
export type ClusterId = string & { __brand: "ClusterId" }
export type GalaxyId = string & { __brand: "GalaxyId" }
export type SectorId = string & { __brand: "SectorId" }
export type SystemId = string & { __brand: "SystemId" }
export type BodyId = string & { __brand: "BodyId" }
export type SubObjectId = string & { __brand: "SubObjectId" }
export type CommandId = string & { __brand: "CommandId" }

local MAX_STABLE_ID_BYTES = 64
local MIN_COMMAND_ID_BYTES = 8
local MAX_SAFE_INTEGER = 9007199254740991

-- Byte -> allowed lookup, built once.
local ALLOWED: { [number]: boolean } = {}
for byte = 48, 57 do
	ALLOWED[byte] = true -- 0-9
end
for byte = 65, 90 do
	ALLOWED[byte] = true -- A-Z
end
for byte = 97, 122 do
	ALLOWED[byte] = true -- a-z
end
ALLOWED[95] = true -- _
ALLOWED[46] = true -- .
ALLOWED[45] = true -- -

local Ids = {}

Ids.MAX_STABLE_ID_BYTES = MAX_STABLE_ID_BYTES

-- True when text is 1-64 bytes of the stable-ID alphabet.
function Ids.isStableIdText(text: string): boolean
	local length = #text
	if length < 1 or length > MAX_STABLE_ID_BYTES then
		return false
	end
	for i = 1, length do
		if not ALLOWED[string.byte(text, i)] then
			return false
		end
	end
	return true
end

local function parseStable(raw: unknown, label: string, minBytes: number): Result<string>
	if type(raw) ~= "string" then
		return Result.err(ErrorCodes.ID_INVALID, label .. " must be a string")
	end
	if #raw < minBytes or not Ids.isStableIdText(raw) then
		return Result.err(ErrorCodes.ID_INVALID, label .. " must be stable-ID text", { length = #raw })
	end
	return Result.ok(raw)
end

function Ids.userId(raw: unknown): Result<UserId>
	if type(raw) ~= "number" or raw ~= raw or raw < 1 or raw > MAX_SAFE_INTEGER or raw ~= math.floor(raw) then
		return Result.err(ErrorCodes.ID_INVALID, "UserId must be a positive safe integer")
	end
	return Result.ok(raw :: any)
end

function Ids.universeId(raw: unknown): Result<UniverseId>
	return parseStable(raw, "UniverseId", 1) :: any
end

function Ids.epochId(raw: unknown): Result<EpochId>
	return parseStable(raw, "EpochId", 1) :: any
end

function Ids.clusterId(raw: unknown): Result<ClusterId>
	return parseStable(raw, "ClusterId", 1) :: any
end

function Ids.galaxyId(raw: unknown): Result<GalaxyId>
	return parseStable(raw, "GalaxyId", 1) :: any
end

function Ids.sectorId(raw: unknown): Result<SectorId>
	return parseStable(raw, "SectorId", 1) :: any
end

function Ids.systemId(raw: unknown): Result<SystemId>
	return parseStable(raw, "SystemId", 1) :: any
end

function Ids.bodyId(raw: unknown): Result<BodyId>
	return parseStable(raw, "BodyId", 1) :: any
end

function Ids.subObjectId(raw: unknown): Result<SubObjectId>
	return parseStable(raw, "SubObjectId", 1) :: any
end

-- Client-supplied idempotency key: stable-ID alphabet, 8-64 bytes (GUID-like).
function Ids.commandId(raw: unknown): Result<CommandId>
	return parseStable(raw, "CommandId", MIN_COMMAND_ID_BYTES) :: any
end

return Ids
