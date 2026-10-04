--!strict
--[[
	RngStreams: named, independent RNG streams so cosmetic draws can never perturb canonical simulation.

	Each stream's seed is derived from (baseSeed, "stream", streamName, generatorVersion); streams share no state, so
	consuming the "visual" stream any number of times cannot change a single value of "positions".

	Two ACCESSORS enforce the split structurally:
	    set.canonical:get(name)  only STREAMS marked "canonical"  (server + client simulation inputs)
	    set.cosmetic:get(name)   only STREAMS marked "cosmetic"   (client presentation)
	Presentation code is handed only `set.cosmetic`, so it has no handle on a canonical stream.

	Requesting an unregistered stream, or one through the wrong accessor, is a programmer error and raises.
	Adding a stream is an explicit registry edit (a generator-version event if canonical).

	Authority: shared, pure.
]]

local Result = require(script.Parent.Parent.Core.Result)
local Rng = require(script.Parent.Rng)
local Seed = require(script.Parent.Seed)
local Versions = require(script.Parent.Versions)

type Rng = Rng.Rng
type Seed = Seed.Seed
type GeneratorVersion = Versions.GeneratorVersion

export type StreamClass = "canonical" | "cosmetic"
export type StreamAccessor = {
	class: StreamClass,
	get: (self: StreamAccessor, name: string) -> Rng,
	seedOf: (self: StreamAccessor, name: string) -> Seed,
}
export type StreamSet = {
	baseSeed: Seed,
	generatorVersion: GeneratorVersion,
	canonical: StreamAccessor,
	cosmetic: StreamAccessor,
}

-- The registry. Names follow 08-PROCEDURAL-GENERATION.md; "names" is cosmetic (display strings only; saved
-- designations are IDs, never RNG output).
local STREAMS: { [string]: StreamClass } = table.freeze({
	morphology = "canonical",
	positions = "canonical",
	composition = "canonical",
	anomalies = "canonical",
	names = "cosmetic",
	visual = "cosmetic",
})

local RngStreams = {}

RngStreams.REGISTRY = STREAMS

local function newAccessor(baseSeed: Seed, generatorVersion: GeneratorVersion, class: StreamClass): StreamAccessor
	local cache: { [string]: Rng } = {}
	local seeds: { [string]: Seed } = {}

	local accessor = { class = class } :: StreamAccessor

	local function seedFor(name: string): Seed
		local declared = STREAMS[name]
		if declared == nil then
			error(string.format("RngStreams: stream '%s' is not registered", name), 3)
		end
		if declared ~= class then
			error(string.format("RngStreams: stream '%s' is %s and is not available from the %s accessor", name, declared, class), 3)
		end
		local cached = seeds[name]
		if cached ~= nil then
			return cached
		end
		-- Registered names are valid stable IDs, so derive cannot fail; unwrap keeps the invariant loud.
		local derived = Result.unwrap(Seed.derive(baseSeed, "stream", name, generatorVersion))
		seeds[name] = derived
		return derived
	end

	function accessor.get(_self: StreamAccessor, name: string): Rng
		local existing = cache[name]
		if existing ~= nil then
			return existing
		end
		local created = Rng.new(seedFor(name))
		cache[name] = created
		return created
	end

	function accessor.seedOf(_self: StreamAccessor, name: string): Seed
		return seedFor(name)
	end

	return accessor
end

-- Creates a fresh stream set. Two sets built from the same (baseSeed, generatorVersion) produce identical streams.
function RngStreams.new(baseSeed: Seed, generatorVersion: GeneratorVersion): StreamSet
	return {
		baseSeed = baseSeed,
		generatorVersion = generatorVersion,
		canonical = newAccessor(baseSeed, generatorVersion, "canonical"),
		cosmetic = newAccessor(baseSeed, generatorVersion, "cosmetic"),
	}
end

return RngStreams
