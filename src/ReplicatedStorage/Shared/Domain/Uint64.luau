--!strict
--[[
	Uint64: exact unsigned 64-bit arithmetic on (hi, lo) uint32 lane pairs.

	Luau numbers are IEEE doubles (integers are exact below 2^53), so 64-bit math is assembled from
	16-bit limbs whose partial products stay below 2^53. Every function is pure and allocation-free
	(results are returned as multiple values, never tables).

	Spec: docs/specs/DETERMINISM.md. Cross-checked against a BigInt reference in tools/reference.

	Authority: shared, pure.
]]

local TWO16 = 65536
local TWO32 = 4294967296

local Uint64 = {}

-- Low 32 bits of a * b for uint32 a, b.
function Uint64.mul32(a: number, b: number): number
	local aHigh = bit32.rshift(a, 16)
	local aLow = bit32.band(a, 0xFFFF)
	-- aHigh * b and aLow * b are both < 2^48 (exact). Only the low 16 bits of aHigh * b survive the shift.
	local cross = ((aHigh * b) % TWO16) * TWO16
	return (aLow * b + cross) % TWO32
end

-- Full 64-bit product of uint32 a, b as (hi, lo).
function Uint64.mulWide32(a: number, b: number): (number, number)
	local a1 = bit32.rshift(a, 16)
	local a0 = bit32.band(a, 0xFFFF)
	local b1 = bit32.rshift(b, 16)
	local b0 = bit32.band(b, 0xFFFF)
	local p00 = a0 * b0 -- < 2^32
	local mid = a0 * b1 + a1 * b0 -- < 2^33
	local p11 = a1 * b1 -- < 2^32
	local lowSum = p00 + (mid % TWO16) * TWO16 -- < 2^33
	local lo = lowSum % TWO32
	local hi = p11 + math.floor(mid / TWO16) + math.floor(lowSum / TWO32)
	return hi, lo
end

-- Low 64 bits of (aHi:aLo) * (bHi:bLo).
function Uint64.mul(aHi: number, aLo: number, bHi: number, bLo: number): (number, number)
	local hi, lo = Uint64.mulWide32(aLo, bLo)
	hi = (hi + Uint64.mul32(aHi, bLo) + Uint64.mul32(aLo, bHi)) % TWO32
	return hi, lo
end

-- (aHi:aLo) + (bHi:bLo) modulo 2^64.
function Uint64.add(aHi: number, aLo: number, bHi: number, bLo: number): (number, number)
	local lo = aLo + bLo
	local carry = 0
	if lo >= TWO32 then
		lo -= TWO32
		carry = 1
	end
	return (aHi + bHi + carry) % TWO32, lo
end

function Uint64.xor(aHi: number, aLo: number, bHi: number, bLo: number): (number, number)
	return bit32.bxor(aHi, bHi), bit32.bxor(aLo, bLo)
end

-- Logical right shift by n in [0, 63].
function Uint64.shr(hi: number, lo: number, n: number): (number, number)
	if n == 0 then
		return hi, lo
	elseif n < 32 then
		return bit32.rshift(hi, n), bit32.bor(bit32.rshift(lo, n), bit32.lshift(hi, 32 - n))
	elseif n == 32 then
		return 0, hi
	end
	return 0, bit32.rshift(hi, n - 32)
end

-- 16 lowercase hex digits, high lane first.
function Uint64.toHex(hi: number, lo: number): string
	return string.format("%08x%08x", hi, lo)
end

local function hexDigit(byte: number): number?
	if byte >= 48 and byte <= 57 then
		return byte - 48
	elseif byte >= 97 and byte <= 102 then
		return byte - 87
	end
	return nil
end

-- Parses exactly 16 lowercase hex digits. Returns nil on any other shape.
function Uint64.fromHex(text: string): (number?, number?)
	if #text ~= 16 then
		return nil, nil
	end
	local hi, lo = 0, 0
	for i = 1, 16 do
		local digit = hexDigit(string.byte(text, i))
		if digit == nil then
			return nil, nil
		end
		if i <= 8 then
			hi = hi * 16 + digit
		else
			lo = lo * 16 + digit
		end
	end
	return hi, lo
end

return Uint64
