--!strict
--[[
	CanonicalEncode ("UC-CANON-V1"): one-and-only-one byte encoding for plain data, with a bounded decoder.

	It serves three jobs: (1) stable checksums of persisted records, (2) the size-measurable wire body for command
	envelopes on every transport, (3) a determinism oracle (iteration order of Lua tables cannot affect output).

	Grammar (no whitespace, no terminators except where shown):
	    value   := 'T' | 'F'                         booleans
	             | 'i' <decimal> ';'                 integer with |n| <= 2^53-1, no leading zeros, never "-0"
	             | 'd' <16 lowercase hex>            IEEE-754 binary64 big-endian; ONLY for non-integers or |n| > 2^53-1
	             | 's' <len> ':' <len raw bytes>     string
	             | 'a' <count> ':' value*count       array (keys exactly 1..count); the empty table is 'a0:'
	             | 'm' <count> ':' (key value)*count map, count >= 1; key := 's' <len> ':' bytes; keys strictly
	                                                  ascending by BYTE order (Bytes.compare)
	Not representable (rejected): nil, NaN, +-inf, functions, userdata, Instances, tables with metatables, mixed or
	sparse tables, non-string map keys. Decoding is strict: non-canonical encodings (e.g. 'm0:', "i01;", an integer
	written as 'd', unsorted keys, trailing bytes) are rejected, so encode(decode(x)) == x for every accepted x.

	Every operation is bounded by Limits (bytes, depth, nodes, string size, container size). Decoder failures are
	typed Results; the decoder never raises on hostile input.

	Spec: docs/specs/DETERMINISM.md. Reference implementation: tools/reference/uc-reference.mjs.
	Authority: shared, pure.
]]

local Bytes = require(script.Parent.Parent.Core.Bytes)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Hash64 = require(script.Parent.Hash64)
local Result = require(script.Parent.Parent.Core.Result)
local Uint64 = require(script.Parent.Uint64)

type Result<T> = Result.Result<T>

export type Limits = {
	maxBytes: number,
	maxDepth: number,
	maxNodes: number,
	maxStringBytes: number,
	maxContainerEntries: number,
}

local MAX_SAFE_INTEGER = 9007199254740991
local MAX_DIGITS = 16

local CanonicalEncode = {}

CanonicalEncode.DEFAULT_LIMITS = table.freeze({
	maxBytes = 1048576,
	maxDepth = 12,
	maxNodes = 65536,
	maxStringBytes = 65536,
	maxContainerEntries = 4096,
} :: Limits)

-- ---------------------------------------------------------------------------------------------------------------
-- Encoding
-- ---------------------------------------------------------------------------------------------------------------

type EncodeState = { limits: Limits, nodes: number, err: Result.Err? }

local function failEncode(state: EncodeState, code: string, message: string): boolean
	state.err = Result.err(code, message)
	return false
end

local function encodeValue(value: any, parts: { string }, state: EncodeState, depth: number): boolean
	state.nodes += 1
	if state.nodes > state.limits.maxNodes then
		return failEncode(state, ErrorCodes.CODEC_LIMIT_EXCEEDED, "too many nodes")
	end
	if depth > state.limits.maxDepth then
		return failEncode(state, ErrorCodes.CODEC_LIMIT_EXCEEDED, "nesting too deep")
	end

	local kind = type(value)
	if kind == "boolean" then
		parts[#parts + 1] = if value then "T" else "F"
		return true
	elseif kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return failEncode(state, ErrorCodes.CODEC_NON_FINITE, "NaN and infinity cannot be encoded")
		end
		if value == 0 then
			parts[#parts + 1] = "i0;" -- also normalizes -0
		elseif value == math.floor(value) and value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER then
			parts[#parts + 1] = "i" .. string.format("%.0f", value) .. ";"
		else
			parts[#parts + 1] = "d" .. Bytes.toHex(string.pack(">d", value))
		end
		return true
	elseif kind == "string" then
		if #value > state.limits.maxStringBytes then
			return failEncode(state, ErrorCodes.CODEC_LIMIT_EXCEEDED, "string too long")
		end
		parts[#parts + 1] = "s" .. #value .. ":" .. value
		return true
	elseif kind ~= "table" then
		return failEncode(state, ErrorCodes.CODEC_UNSUPPORTED_TYPE, "unsupported value type: " .. kind)
	end

	if getmetatable(value) ~= nil then
		return failEncode(state, ErrorCodes.CODEC_UNSUPPORTED_TYPE, "tables with metatables cannot be encoded")
	end

	local count = 0
	for _ in pairs(value) do
		count += 1
	end
	if count > state.limits.maxContainerEntries then
		return failEncode(state, ErrorCodes.CODEC_LIMIT_EXCEEDED, "container too large")
	end
	if count == 0 then
		parts[#parts + 1] = "a0:"
		return true
	end

	local isArray = #value == count
	if isArray then
		for i = 1, count do
			if value[i] == nil then
				isArray = false
				break
			end
		end
	end

	if isArray then
		parts[#parts + 1] = "a" .. count .. ":"
		for i = 1, count do
			if not encodeValue(value[i], parts, state, depth + 1) then
				return false
			end
		end
		return true
	end

	local keys = table.create(count)
	for key in pairs(value) do
		if type(key) ~= "string" then
			return failEncode(state, ErrorCodes.CODEC_UNSUPPORTED_TYPE, "map keys must be strings (mixed or sparse table)")
		end
		if #key > state.limits.maxStringBytes then
			return failEncode(state, ErrorCodes.CODEC_LIMIT_EXCEEDED, "map key too long")
		end
		keys[#keys + 1] = key
	end
	Bytes.sortStrings(keys)
	parts[#parts + 1] = "m" .. count .. ":"
	for _, key in ipairs(keys) do
		parts[#parts + 1] = "s" .. #key .. ":" .. key
		if not encodeValue(value[key], parts, state, depth + 1) then
			return false
		end
	end
	return true
end

function CanonicalEncode.encode(value: any, limits: Limits?): Result<string>
	local activeLimits = limits or CanonicalEncode.DEFAULT_LIMITS
	local state: EncodeState = { limits = activeLimits, nodes = 0, err = nil }
	local parts: { string } = {}
	if not encodeValue(value, parts, state, 0) then
		return state.err or Result.err(ErrorCodes.CODEC_ENCODE_FAILED, "encode failed")
	end
	local text = table.concat(parts)
	if #text > activeLimits.maxBytes then
		return Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "encoded value exceeds maxBytes", { bytes = #text })
	end
	return Result.ok(text)
end

-- ---------------------------------------------------------------------------------------------------------------
-- Decoding (strict, bounded, never raises)
-- ---------------------------------------------------------------------------------------------------------------

type DecodeState = { text: string, length: number, pos: number, limits: Limits, nodes: number, err: Result.Err? }

local function failDecode(state: DecodeState, code: string, message: string): (boolean, any)
	state.err = Result.err(code, message, { position = state.pos })
	return false, nil
end

local function isDigit(byte: number): boolean
	return byte >= 48 and byte <= 57
end

-- Reads a canonical decimal up to `terminator`, advancing past it. Returns (ok, number).
local function readDecimal(state: DecodeState, terminator: number, allowNegative: boolean): (boolean, number)
	local text, length = state.text, state.length
	local start = state.pos
	local pos = start
	local negative = false
	if allowNegative and pos <= length and string.byte(text, pos) == 45 then
		negative = true
		pos += 1
	end
	local digitsStart = pos
	while pos <= length and isDigit(string.byte(text, pos)) do
		pos += 1
	end
	local digitCount = pos - digitsStart
	if digitCount < 1 or digitCount > MAX_DIGITS or pos > length or string.byte(text, pos) ~= terminator then
		state.pos = start
		state.err = Result.err(ErrorCodes.CODEC_DECODE_FAILED, "malformed number", { position = start })
		return false, 0
	end
	if digitCount > 1 and string.byte(text, digitsStart) == 48 then
		state.pos = start
		state.err = Result.err(ErrorCodes.CODEC_DECODE_FAILED, "leading zero in number", { position = start })
		return false, 0
	end
	local magnitude = tonumber(string.sub(text, digitsStart, pos - 1))
	if magnitude == nil or magnitude > MAX_SAFE_INTEGER or (negative and magnitude == 0) then
		state.pos = start
		state.err = Result.err(ErrorCodes.CODEC_DECODE_FAILED, "number out of canonical range", { position = start })
		return false, 0
	end
	state.pos = pos + 1
	return true, if negative then -magnitude else magnitude
end

local function readString(state: DecodeState): (boolean, string)
	-- state.pos is just past the 's' tag
	local ok, size = readDecimal(state, 58, false)
	if not ok then
		return false, ""
	end
	if size > state.limits.maxStringBytes then
		state.err = Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "string too long", { position = state.pos })
		return false, ""
	end
	local last = state.pos + size - 1
	if last > state.length then
		state.err = Result.err(ErrorCodes.CODEC_DECODE_FAILED, "string runs past end of input", { position = state.pos })
		return false, ""
	end
	local value = string.sub(state.text, state.pos, last)
	state.pos = last + 1
	return true, value
end

local function hexValue(byte: number): number?
	if byte >= 48 and byte <= 57 then
		return byte - 48
	elseif byte >= 97 and byte <= 102 then
		return byte - 87
	end
	return nil
end

local function decodeValue(state: DecodeState, depth: number): (boolean, any)
	state.nodes += 1
	if state.nodes > state.limits.maxNodes then
		state.err = Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "too many nodes", { position = state.pos })
		return false, nil
	end
	if depth > state.limits.maxDepth then
		state.err = Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "nesting too deep", { position = state.pos })
		return false, nil
	end
	if state.pos > state.length then
		return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "unexpected end of input")
	end

	local text = state.text
	local tag = string.byte(text, state.pos)
	state.pos += 1

	if tag == 84 then -- 'T'
		return true, true
	elseif tag == 70 then -- 'F'
		return true, false
	elseif tag == 105 then -- 'i'
		return readDecimal(state, 59, true)
	elseif tag == 100 then -- 'd'
		if state.pos + 15 > state.length then
			return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "truncated float")
		end
		local bytes = table.create(8)
		for i = 0, 7 do
			local high = hexValue(string.byte(text, state.pos + i * 2))
			local low = hexValue(string.byte(text, state.pos + i * 2 + 1))
			if high == nil or low == nil then
				return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "float must be lowercase hex")
			end
			bytes[i + 1] = string.char(high * 16 + low)
		end
		local packed = table.concat(bytes)
		local value = string.unpack(">d", packed)
		if value ~= value or value == math.huge or value == -math.huge then
			return failDecode(state, ErrorCodes.CODEC_NON_FINITE, "non-finite float")
		end
		if value == math.floor(value) and value >= -MAX_SAFE_INTEGER and value <= MAX_SAFE_INTEGER then
			return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "integer-valued float must use the integer form")
		end
		state.pos += 16
		return true, value
	elseif tag == 115 then -- 's'
		return readString(state)
	elseif tag == 97 then -- 'a'
		local ok, count = readDecimal(state, 58, false)
		if not ok then
			return false, nil
		end
		if count > state.limits.maxContainerEntries or count > state.length - state.pos + 1 then
			state.err = Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "array too large", { position = state.pos })
			return false, nil
		end
		local list = table.create(count)
		for i = 1, count do
			local elementOk, element = decodeValue(state, depth + 1)
			if not elementOk then
				return false, nil
			end
			list[i] = element
		end
		return true, list
	elseif tag == 109 then -- 'm'
		local ok, count = readDecimal(state, 58, false)
		if not ok then
			return false, nil
		end
		if count < 1 then
			return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "empty map must be encoded as 'a0:'")
		end
		if count > state.limits.maxContainerEntries or count > state.length - state.pos + 1 then
			state.err = Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "map too large", { position = state.pos })
			return false, nil
		end
		local map: { [string]: any } = {}
		local previousKey: string? = nil
		for _ = 1, count do
			if state.pos > state.length or string.byte(text, state.pos) ~= 115 then
				return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "map key must be a string")
			end
			state.pos += 1
			local keyOk, key = readString(state)
			if not keyOk then
				return false, nil
			end
			if previousKey ~= nil and Bytes.compare(previousKey, key) >= 0 then
				return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "map keys must be strictly ascending")
			end
			previousKey = key
			local valueOk, value = decodeValue(state, depth + 1)
			if not valueOk then
				return false, nil
			end
			map[key] = value
		end
		return true, map
	end

	state.pos -= 1
	return failDecode(state, ErrorCodes.CODEC_DECODE_FAILED, "unknown tag byte")
end

function CanonicalEncode.decode(text: string, limits: Limits?): Result<any>
	local activeLimits = limits or CanonicalEncode.DEFAULT_LIMITS
	if type(text) ~= "string" then
		return Result.err(ErrorCodes.CODEC_DECODE_FAILED, "input must be a string")
	end
	if #text > activeLimits.maxBytes then
		return Result.err(ErrorCodes.CODEC_LIMIT_EXCEEDED, "input exceeds maxBytes", { bytes = #text })
	end
	local state: DecodeState = { text = text, length = #text, pos = 1, limits = activeLimits, nodes = 0, err = nil }
	local ok, value = decodeValue(state, 0)
	if not ok then
		return state.err or Result.err(ErrorCodes.CODEC_DECODE_FAILED, "decode failed")
	end
	if state.pos <= state.length then
		return Result.err(ErrorCodes.CODEC_DECODE_FAILED, "trailing bytes after value", { position = state.pos })
	end
	return Result.ok(value)
end

-- 16-hex-digit checksum of the canonical encoding (UC-HASH64-V1). Order-independent for table contents.
function CanonicalEncode.checksum(value: any, limits: Limits?): Result<string>
	local encoded = CanonicalEncode.encode(value, limits)
	if not encoded.ok then
		return encoded
	end
	local hi, lo = Hash64.hashString(encoded.value)
	return Result.ok(Uint64.toHex(hi, lo))
end

return CanonicalEncode
