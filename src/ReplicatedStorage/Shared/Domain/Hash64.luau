--!strict
--[[
	Hash64 ("UC-HASH64-V1"): FNV-1a 64-bit absorption followed by the MurmurHash3 fmix64 finalizer.

	FNV-1a absorbs bytes one at a time; fmix64 is applied once at the end to avalanche all 64 bits.
	This is a NON-cryptographic hash for deterministic generation, seed derivation and checksums.
	It is never a security boundary.

	State is a (hi, lo) uint32 lane pair threaded through pure functions (no allocation).
	Spec: docs/specs/DETERMINISM.md.

	Authority: shared, pure.
]]

local Uint64 = require(script.Parent.Uint64)

local TWO32 = 4294967296

local Hash64 = {}

-- FNV-1a 64-bit offset basis 0xCBF29CE484222325.
Hash64.OFFSET_HI = 0xCBF29CE4
Hash64.OFFSET_LO = 0x84222325

-- One FNV-1a step: h = (h xor byte) * 0x100000001B3 (mod 2^64).
-- 0x100000001B3 = 2^40 + 435, so h * prime = h * 435 + (low32(h) << 8) in the high lane.
function Hash64.absorbByte(hi: number, lo: number, byte: number): (number, number)
	lo = bit32.bxor(lo, byte)
	local lowProduct = lo * 435 -- < 2^42 (exact)
	local newLo = lowProduct % TWO32
	local carry = (lowProduct - newLo) / TWO32
	local shifted = (lo * 256) % TWO32
	local newHi = (hi * 435 + carry + shifted) % TWO32
	return newHi, newLo
end

-- Absorbs a uint32 as four little-endian bytes.
function Hash64.absorbU32(hi: number, lo: number, value: number): (number, number)
	hi, lo = Hash64.absorbByte(hi, lo, bit32.band(value, 0xFF))
	hi, lo = Hash64.absorbByte(hi, lo, bit32.band(bit32.rshift(value, 8), 0xFF))
	hi, lo = Hash64.absorbByte(hi, lo, bit32.band(bit32.rshift(value, 16), 0xFF))
	hi, lo = Hash64.absorbByte(hi, lo, bit32.rshift(value, 24))
	return hi, lo
end

-- Absorbs every byte of the string (no length prefix; callers that need unambiguity use absorbField).
function Hash64.absorbString(hi: number, lo: number, text: string): (number, number)
	for i = 1, #text do
		hi, lo = Hash64.absorbByte(hi, lo, string.byte(text, i))
	end
	return hi, lo
end

-- Length-prefixed field: u32 length (little endian) then the bytes. ("ab","c") and ("a","bc") cannot collide.
function Hash64.absorbField(hi: number, lo: number, text: string): (number, number)
	hi, lo = Hash64.absorbU32(hi, lo, #text)
	return Hash64.absorbString(hi, lo, text)
end

-- MurmurHash3 fmix64 finalizer.
function Hash64.fmix(hi: number, lo: number): (number, number)
	local shiftedHi, shiftedLo = Uint64.shr(hi, lo, 33)
	hi, lo = Uint64.xor(hi, lo, shiftedHi, shiftedLo)
	hi, lo = Uint64.mul(hi, lo, 0xFF51AFD7, 0xED558CCD)
	shiftedHi, shiftedLo = Uint64.shr(hi, lo, 33)
	hi, lo = Uint64.xor(hi, lo, shiftedHi, shiftedLo)
	hi, lo = Uint64.mul(hi, lo, 0xC4CEB9FE, 0x1A85EC53)
	shiftedHi, shiftedLo = Uint64.shr(hi, lo, 33)
	return Uint64.xor(hi, lo, shiftedHi, shiftedLo)
end

-- Convenience: fmix(FNV-1a(text)) for checksums of whole strings.
function Hash64.hashString(text: string): (number, number)
	local hi, lo = Hash64.absorbString(Hash64.OFFSET_HI, Hash64.OFFSET_LO, text)
	return Hash64.fmix(hi, lo)
end

return Hash64
