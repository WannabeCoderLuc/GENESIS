--!strict
--[[
	Seed: canonical 64-bit seed and deterministic hierarchical derivation ("UC-SEED-V1").

	A Seed is an immutable (hi, lo) pair of uint32 lanes; its persisted/transport form is exactly 16 lowercase hex
	digits. Child seeds are derived from STABLE inputs only:

	    childSeed = fmix64( FNV-1a64( "UCSEEDV1" | u32 generatorVersion | parent.hi | parent.lo
	                                  | field(namespace) | field(stableId) ) )

	where field(x) = u32 length + bytes (unambiguous). Nothing else may influence a derived seed: not time, frame
	count, traversal order, dictionary order, locale, or client state (08-PROCEDURAL-GENERATION.md).

	The only legitimate source of nondeterminism is choosing a NEW universe's root seed, which happens once, on the
	server, in infrastructure code, and is then persisted. This module never creates entropy.

	Spec: docs/specs/DETERMINISM.md. Authority: shared, pure.
]]

local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Hash64 = require(script.Parent.Hash64)
local Ids = require(script.Parent.Ids)
local Result = require(script.Parent.Parent.Core.Result)
local Uint64 = require(script.Parent.Uint64)
local Versions = require(script.Parent.Versions)

type Result<T> = Result.Result<T>
type GeneratorVersion = Versions.GeneratorVersion

export type Seed = { hi: number, lo: number }
export type SeedPathSegment = { namespace: string, stableId: string }

local DOMAIN_TAG = "UCSEEDV1"
local ROOT_TAG = "UCROOTV1"
local TWO32 = 4294967296

local Seed = {}

local function isUint32(value: unknown): boolean
	return type(value) == "number" and value == value and value >= 0 and value < TWO32 and value == math.floor(value)
end

-- Namespaces are lowercase tags such as "epoch", "sector", "stream": [a-z][a-z0-9_.-]{0,31}.
local function isNamespaceText(text: string): boolean
	local length = #text
	if length < 1 or length > 32 then
		return false
	end
	local first = string.byte(text, 1)
	if first < 97 or first > 122 then
		return false
	end
	for i = 2, length do
		local byte = string.byte(text, i)
		local isLower = byte >= 97 and byte <= 122
		local isDigit = byte >= 48 and byte <= 57
		if not (isLower or isDigit or byte == 95 or byte == 46 or byte == 45) then
			return false
		end
	end
	return true
end

function Seed.fromLanes(hi: unknown, lo: unknown): Result<Seed>
	if not isUint32(hi) or not isUint32(lo) then
		return Result.err(ErrorCodes.SEED_INVALID_LANE, "seed lanes must be uint32 integers")
	end
	return Result.ok(table.freeze({ hi = hi :: number, lo = lo :: number }))
end

function Seed.toHex(seed: Seed): string
	return Uint64.toHex(seed.hi, seed.lo)
end

function Seed.fromHex(text: unknown): Result<Seed>
	if type(text) ~= "string" then
		return Result.err(ErrorCodes.SEED_INVALID_HEX, "seed hex must be a string")
	end
	local hi, lo = Uint64.fromHex(text)
	if hi == nil or lo == nil then
		return Result.err(ErrorCodes.SEED_INVALID_HEX, "seed hex must be 16 lowercase hex digits")
	end
	return Result.ok(table.freeze({ hi = hi, lo = lo }))
end

function Seed.equals(a: Seed, b: Seed): boolean
	return a.hi == b.hi and a.lo == b.lo
end

-- Deterministic seed from free text (for challenges, fixtures and developer tooling), domain-separated from
-- derive(). `purpose` is a namespace such as "challenge".
function Seed.fromText(purpose: string, text: string): Result<Seed>
	if not isNamespaceText(purpose) then
		return Result.err(ErrorCodes.SEED_INVALID_NAMESPACE, "purpose must be a lowercase namespace")
	end
	local hi, lo = Hash64.absorbString(Hash64.OFFSET_HI, Hash64.OFFSET_LO, ROOT_TAG)
	hi, lo = Hash64.absorbField(hi, lo, purpose)
	hi, lo = Hash64.absorbField(hi, lo, text)
	hi, lo = Hash64.fmix(hi, lo)
	return Result.ok(table.freeze({ hi = hi, lo = lo }))
end

-- Derives a child seed. namespace: lowercase tag; stableId: stable-ID text (see Ids).
function Seed.derive(parent: Seed, namespace: string, stableId: string, generatorVersion: GeneratorVersion): Result<Seed>
	if not isNamespaceText(namespace) then
		return Result.err(ErrorCodes.SEED_INVALID_NAMESPACE, "namespace must be a lowercase tag", { namespace = namespace })
	end
	if not Ids.isStableIdText(stableId) then
		return Result.err(ErrorCodes.SEED_INVALID_STABLE_ID, "stableId must be stable-ID text", { length = #stableId })
	end
	local hi, lo = Hash64.absorbString(Hash64.OFFSET_HI, Hash64.OFFSET_LO, DOMAIN_TAG)
	hi, lo = Hash64.absorbU32(hi, lo, generatorVersion :: number)
	hi, lo = Hash64.absorbU32(hi, lo, parent.hi)
	hi, lo = Hash64.absorbU32(hi, lo, parent.lo)
	hi, lo = Hash64.absorbField(hi, lo, namespace)
	hi, lo = Hash64.absorbField(hi, lo, stableId)
	hi, lo = Hash64.fmix(hi, lo)
	return Result.ok(table.freeze({ hi = hi, lo = lo }))
end

-- Walks root -> ... -> leaf. The result depends only on the ordered path, never on how it was reached.
function Seed.deriveAlongPath(root: Seed, path: { SeedPathSegment }, generatorVersion: GeneratorVersion): Result<Seed>
	local current = root
	for _, segment in ipairs(path) do
		local derived = Seed.derive(current, segment.namespace, segment.stableId, generatorVersion)
		if not derived.ok then
			return derived
		end
		current = derived.value
	end
	return Result.ok(current)
end

return Seed
