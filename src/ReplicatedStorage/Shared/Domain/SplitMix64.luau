--!strict
--[[
	SplitMix64: the standard 64-bit seed expander (Steele/Lea/Flood; same constants as the xoshiro authors' seeder).
	Used only to expand a 64-bit Seed into RNG state words.

	Authority: shared, pure.
]]

local Uint64 = require(script.Parent.Uint64)

local SplitMix64 = {}

-- Advances the state by the golden-gamma increment and returns (newStateHi, newStateLo, outHi, outLo).
function SplitMix64.next(stateHi: number, stateLo: number): (number, number, number, number)
	local newHi, newLo = Uint64.add(stateHi, stateLo, 0x9E3779B9, 0x7F4A7C15)
	local zHi, zLo = newHi, newLo
	local sHi, sLo = Uint64.shr(zHi, zLo, 30)
	zHi, zLo = Uint64.xor(zHi, zLo, sHi, sLo)
	zHi, zLo = Uint64.mul(zHi, zLo, 0xBF58476D, 0x1CE4E5B9)
	sHi, sLo = Uint64.shr(zHi, zLo, 27)
	zHi, zLo = Uint64.xor(zHi, zLo, sHi, sLo)
	zHi, zLo = Uint64.mul(zHi, zLo, 0x94D049BB, 0x133111EB)
	sHi, sLo = Uint64.shr(zHi, zLo, 31)
	zHi, zLo = Uint64.xor(zHi, zLo, sHi, sLo)
	return newHi, newLo, zHi, zLo
end

return SplitMix64
