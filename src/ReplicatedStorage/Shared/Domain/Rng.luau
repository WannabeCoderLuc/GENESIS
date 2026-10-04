--!strict
--[[
	Rng ("UC-RNG-V1"): xoshiro128** (Blackman & Vigna) seeded from a Seed via SplitMix64.

	Pure 32-bit state, so it is exact and fast in Luau. Instances are mutable and owned by a single stream; to get
	independent streams derive separate seeds (see RngStreams) instead of sharing one Rng.

	Seeding: two SplitMix64 outputs o1, o2 from the 64-bit seed give the state words
	    s0 = o1.lo, s1 = o1.hi, s2 = o2.lo, s3 = o2.hi
	(an all-zero state, which xoshiro cannot leave, is replaced by s0 = 1; it is unreachable in practice).

	math.random, Random.new, os.time and tick are never used here (AGENTS.md hard rules).

	Spec: docs/specs/DETERMINISM.md. Authority: shared, pure.
]]

local Seed = require(script.Parent.Seed)
local SplitMix64 = require(script.Parent.SplitMix64)

type Seed = Seed.Seed

export type RngState = { s0: number, s1: number, s2: number, s3: number }

local TWO32 = 4294967296
local TWO26 = 67108864
local TWO53 = 9007199254740992

local Rng = {}
Rng.__index = Rng

export type Rng = typeof(setmetatable({} :: RngState, Rng))

function Rng.new(seed: Seed): Rng
	local stateHi, stateLo, firstHi, firstLo = SplitMix64.next(seed.hi, seed.lo)
	local _, _, secondHi, secondLo = SplitMix64.next(stateHi, stateLo)
	local s0, s1, s2, s3 = firstLo, firstHi, secondLo, secondHi
	if s0 == 0 and s1 == 0 and s2 == 0 and s3 == 0 then
		s0 = 1
	end
	return setmetatable({ s0 = s0, s1 = s1, s2 = s2, s3 = s3 }, Rng)
end

function Rng.fromState(state: RngState): Rng
	return setmetatable({ s0 = state.s0, s1 = state.s1, s2 = state.s2, s3 = state.s3 }, Rng)
end

function Rng.saveState(self: Rng): RngState
	return { s0 = self.s0, s1 = self.s1, s2 = self.s2, s3 = self.s3 }
end

-- Next uint32 in [0, 2^32).
function Rng.next32(self: Rng): number
	local s0, s1, s2, s3 = self.s0, self.s1, self.s2, self.s3
	local result = (bit32.lrotate((s1 * 5) % TWO32, 7) * 9) % TWO32
	local t = bit32.lshift(s1, 9)
	s2 = bit32.bxor(s2, s0)
	s3 = bit32.bxor(s3, s1)
	s1 = bit32.bxor(s1, s2)
	s0 = bit32.bxor(s0, s3)
	s2 = bit32.bxor(s2, t)
	s3 = bit32.lrotate(s3, 11)
	self.s0, self.s1, self.s2, self.s3 = s0, s1, s2, s3
	return result
end

-- Next 53-bit unsigned integer in [0, 2^53): (next32 >> 5) * 2^26 + (next32 >> 6).
function Rng.nextU53(self: Rng): number
	local high = bit32.rshift(self:next32(), 5)
	local low = bit32.rshift(self:next32(), 6)
	return high * TWO26 + low
end

-- Uniform float in [0, 1) with 53 bits of precision (always strictly below 1).
function Rng.nextUnit(self: Rng): number
	return self:nextU53() / TWO53
end

-- Uniform float in [min, max]. Rounding can reach max only in the last ulp; callers that need a strict upper
-- bound use nextInt. Finite bounds with min <= max are required.
function Rng.nextRange(self: Rng, min: number, max: number): number
	assert(min == min and max == max and min > -math.huge and max < math.huge and min <= max, "Rng.nextRange: finite bounds with min <= max required")
	local value = min + self:nextUnit() * (max - min)
	if value > max then
		return max
	end
	return value
end

-- Uniform integer in [lo, hi] (inclusive) by rejection sampling, so there is no modulo bias. A range of exactly
-- one value consumes no draw. Requires integer bounds and hi - lo + 1 <= 2^53.
function Rng.nextInt(self: Rng, lo: number, hi: number): number
	assert(lo == math.floor(lo) and hi == math.floor(hi) and lo <= hi, "Rng.nextInt: integer bounds with lo <= hi required")
	-- Guard on hi - lo (exact) rather than hi - lo + 1, which would round once it reaches 2^53.
	assert(hi - lo <= TWO53 - 1, "Rng.nextInt: range too large")
	local range = hi - lo + 1
	if range == 1 then
		return lo
	end
	if range <= TWO32 then
		local limit = TWO32 - (TWO32 % range)
		local draw = self:next32()
		while draw >= limit do
			draw = self:next32()
		end
		return lo + (draw % range)
	end
	local limit = TWO53 - (TWO53 % range)
	local draw = self:nextU53()
	while draw >= limit do
		draw = self:nextU53()
	end
	return lo + (draw % range)
end

-- True with probability chancePermille / 1000 (0 never, 1000 always).
function Rng.chancePermille(self: Rng, chancePermille: number): boolean
	assert(chancePermille >= 0 and chancePermille <= 1000, "Rng.chancePermille: 0..1000 required")
	if chancePermille == 0 then
		return false
	elseif chancePermille == 1000 then
		return true
	end
	return self:nextInt(0, 999) < chancePermille
end

-- Fisher-Yates shuffle of an array in place (descending index). Returns the same array.
function Rng.shuffle<T>(self: Rng, list: { T }): { T }
	for i = #list, 2, -1 do
		local j = self:nextInt(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

return Rng
