--!strict
--[[
	Bytes: locale-independent byte-string helpers.
	Canonical ordering must never depend on string comparison semantics of the host, so ordering used by
	canonical encoding and sorted-unique validation goes through Bytes.compare.

	Authority: shared, pure.
]]

local Bytes = {}

-- Bytewise lexicographic comparison. Returns -1, 0 or 1.
function Bytes.compare(a: string, b: string): number
	if a == b then
		return 0
	end
	local lengthA, lengthB = #a, #b
	local shared = if lengthA < lengthB then lengthA else lengthB
	for i = 1, shared do
		local byteA, byteB = string.byte(a, i), string.byte(b, i)
		if byteA ~= byteB then
			return if byteA < byteB then -1 else 1
		end
	end
	if lengthA == lengthB then
		return 0
	end
	return if lengthA < lengthB then -1 else 1
end

function Bytes.less(a: string, b: string): boolean
	return Bytes.compare(a, b) < 0
end

-- Sorts strings in place by bytewise order and returns the same array.
function Bytes.sortStrings(list: { string }): { string }
	table.sort(list, Bytes.less)
	return list
end

-- Lowercase hex of every byte in the string.
function Bytes.toHex(s: string): string
	local parts = table.create(#s)
	for i = 1, #s do
		parts[i] = string.format("%02x", string.byte(s, i))
	end
	return table.concat(parts)
end

return Bytes
