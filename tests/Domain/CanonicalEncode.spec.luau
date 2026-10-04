--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local CanonicalEncode = require(Paths.domain("CanonicalEncode"))
local ErrorCodes = require(Paths.core("ErrorCodes"))
local Rng = require(Paths.domain("Rng"))
local Seed = require(Paths.domain("Seed"))
local Vectors = require(Paths.vector("CanonicalVectorsV1"))

local ALLOWED_DECODE_ERRORS = {
	[ErrorCodes.CODEC_DECODE_FAILED] = true,
	[ErrorCodes.CODEC_LIMIT_EXCEEDED] = true,
	[ErrorCodes.CODEC_NON_FINITE] = true,
}

return function(t: TestContext.TestContext)
	local expect = t.expect

	t.test("encoding and checksums match the reference", function()
		for _, case in ipairs(Vectors.valid) do
			expect.equal(expect.isOk(CanonicalEncode.encode(case.value)), case.encoded, case.name)
			expect.equal(expect.isOk(CanonicalEncode.checksum(case.value)), case.checksumHex, case.name .. " checksum")
		end
	end)

	t.test("decode(encode(x)) round-trips every reference value", function()
		for _, case in ipairs(Vectors.valid) do
			local decoded = expect.isOk(CanonicalEncode.decode(case.encoded), case.name)
			expect.deepEqual(decoded, case.value, case.name)
			expect.equal(expect.isOk(CanonicalEncode.encode(decoded)), case.encoded, case.name .. " re-encode")
		end
	end)

	-- Insertion order of a Lua table must not affect output (hash-part order is unspecified).
	t.test("map insertion order does not alter the encoding or checksum", function()
		local keys = { "zeta", "alpha", "Beta", "", "_under", "\u{E9}", "k10", "k9", "k1" }
		local function build(order: { number }): { [string]: number }
			local map: { [string]: number } = {}
			for _, index in ipairs(order) do
				map[keys[index]] = index
			end
			return map
		end
		local forward, reverse, scrambled = {}, {}, {}
		for i = 1, #keys do
			forward[i] = i
			reverse[i] = #keys + 1 - i
			scrambled[i] = ((i * 4) % #keys) + 1 -- 4 is coprime with 9
		end
		local a = expect.isOk(CanonicalEncode.encode(build(forward)))
		expect.equal(expect.isOk(CanonicalEncode.encode(build(reverse))), a)
		expect.equal(expect.isOk(CanonicalEncode.encode(build(scrambled))), a)
		expect.equal(expect.isOk(CanonicalEncode.checksum(build(reverse))), expect.isOk(CanonicalEncode.checksum(build(forward))))
	end)

	t.test("keys sort by byte value, not by locale", function()
		local encoded = expect.isOk(CanonicalEncode.encode({ a = 1, B = 2, ["\u{E9}"] = 3 }))
		expect.equal(encoded, "m3:s1:Bi2;s1:ai1;s2:\u{E9}i3;")
	end)

	t.test("number normalization: -0, integer-valued floats, large integers", function()
		expect.equal(expect.isOk(CanonicalEncode.encode(-0)), "i0;")
		expect.equal(expect.isOk(CanonicalEncode.encode(3.0)), "i3;")
		expect.equal(expect.isOk(CanonicalEncode.encode(9007199254740991)), "i9007199254740991;")
		expect.equal(expect.isOk(CanonicalEncode.encode(-9007199254740991)), "i-9007199254740991;")
		expect.equal(string.sub(expect.isOk(CanonicalEncode.encode(9007199254740992)), 1, 1), "d")
		expect.equal(expect.isOk(CanonicalEncode.encode(0.5)), "d3fe0000000000000")
	end)

	t.test("unrepresentable values are typed encode failures", function()
		expect.isErr(CanonicalEncode.encode(0 / 0), ErrorCodes.CODEC_NON_FINITE)
		expect.isErr(CanonicalEncode.encode(math.huge), ErrorCodes.CODEC_NON_FINITE)
		expect.isErr(CanonicalEncode.encode(-math.huge), ErrorCodes.CODEC_NON_FINITE)
		expect.isErr(CanonicalEncode.encode(print), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		expect.isErr(CanonicalEncode.encode(Instance.new("Folder")), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		expect.isErr(CanonicalEncode.encode(setmetatable({}, {})), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		expect.isErr(CanonicalEncode.encode({ 1, 2, nil, 4 }), nil)
		expect.isErr(CanonicalEncode.encode({ [1] = "a", [3] = "c" }), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		expect.isErr(CanonicalEncode.encode({ [1.5] = "a" }), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		-- selene: allow(mixed_table) -- the mixed table IS the hostile input under test
		expect.isErr(CanonicalEncode.encode({ 1, 2, x = 3 }), ErrorCodes.CODEC_UNSUPPORTED_TYPE)
		local cyclic: { [string]: any } = {}
		cyclic.self = cyclic
		expect.isErr(CanonicalEncode.encode(cyclic), ErrorCodes.CODEC_LIMIT_EXCEEDED)
	end)

	t.test("encode honours its limits", function()
		local tight = { maxBytes = 64, maxDepth = 3, maxNodes = 8, maxStringBytes = 8, maxContainerEntries = 4 }
		expect.isErr(CanonicalEncode.encode("123456789", tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.encode({ { { { 1 } } } }, tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.encode({ 1, 2, 3, 4, 5 }, tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.encode({ 1, 2, 3, 4, 1, 2, 3, 4, 1 }, { maxBytes = 64, maxDepth = 3, maxNodes = 8, maxStringBytes = 8, maxContainerEntries = 16 }), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isOk(CanonicalEncode.encode({ 1, 2, 3 }, tight))
	end)

	-- Strictness: each of these is a plausible hostile or sloppy encoding and must be refused with a typed error.
	t.test("decode rejects every non-canonical or malformed encoding", function()
		local invalid = {
			"", "x", "TT", "T ", "F\n", "i;", "i01;", "i-0;", "i1", "i--1;", "i1.5;", "ia;", "i9007199254740992;",
			"i99999999999999999;", "i-;",
			"d3ff0000000000000", "d7ff8000000000000", "d7ff0000000000000", "dfff0000000000000", "d3FE0000000000000",
			"d3fe00000000000", "d3fe000000000000000", "d0000000000000000", "d8000000000000000",
			"s5:abc", "s-1:", "s01:a", "s1a", "s:", "s2:a", "s99999999999:", "s4294967296:x",
			"a2:T", "a1:", "a-1:", "a01:T", "a0", "a99999999999:", "a3:TTF" .. "T",
			"m0:", "m1:", "m1:iii", "m1:i1;T", "m1:s1:a", "m2:s1:bTs1:aT", "m2:s1:aTs1:aT", "m2:s1:aTs1:b", "m1:s2:aT",
			"A1:T", "n", "N", "t", "f", "z0:",
			string.rep("a1:", 40) .. "T",
			"a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:a1:T",
		}
		for _, text in ipairs(invalid) do
			local result = CanonicalEncode.decode(text)
			if result.ok then
				error("accepted invalid encoding: " .. expect.describe(text))
			end
			expect.truthy(ALLOWED_DECODE_ERRORS[result.code], "unexpected code " .. result.code .. " for " .. expect.describe(text))
		end
	end)

	t.test("decode honours byte, node and entry limits", function()
		local tight = { maxBytes = 16, maxDepth = 4, maxNodes = 6, maxStringBytes = 4, maxContainerEntries = 3 }
		expect.isErr(CanonicalEncode.decode(string.rep("T", 17), tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.decode("s5:hello", tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.decode("a4:TTTT", tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isErr(CanonicalEncode.decode("a3:a3:TTTa3:TTTa3:TTT", tight), ErrorCodes.CODEC_LIMIT_EXCEEDED)
		expect.isOk(CanonicalEncode.decode("a3:TFT", tight))
	end)

	-- Fuzz: seeded random garbage and mutated valid encodings must never raise, only return typed errors/values.
	t.test("fuzz: decoding hostile bytes never raises and re-encodes any accepted value identically", function()
		local rng = Rng.new(expect.isOk(Seed.fromHex("c0ffee00c0ffee00")))
		local alphabet = "TFidsam0123456789:;-.abcdef"
		local accepted = 0
		for _ = 1, 3000 do
			local length = rng:nextInt(0, 24)
			local bytes = table.create(length)
			for i = 1, length do
				local pick = rng:nextInt(1, #alphabet)
				bytes[i] = string.sub(alphabet, pick, pick)
			end
			local text = table.concat(bytes)
			local ok, result = pcall(CanonicalEncode.decode, text)
			expect.truthy(ok, "decode raised on " .. expect.describe(text))
			if result.ok then
				accepted += 1
				expect.equal(expect.isOk(CanonicalEncode.encode(result.value)), text, "non-canonical acceptance of " .. expect.describe(text))
			else
				expect.truthy(ALLOWED_DECODE_ERRORS[result.code], result.code)
			end
		end
		for _, case in ipairs(Vectors.valid) do
			for _ = 1, 40 do
				local mutated = case.encoded
				local position = rng:nextInt(1, #mutated)
				local replacement = string.char(rng:nextInt(0, 255))
				mutated = string.sub(mutated, 1, position - 1) .. replacement .. string.sub(mutated, position + 1)
				local ok, result = pcall(CanonicalEncode.decode, mutated)
				expect.truthy(ok, "decode raised on mutation of " .. case.name)
				if result.ok then
					expect.equal(expect.isOk(CanonicalEncode.encode(result.value)), mutated, "non-canonical acceptance, " .. case.name)
				end
			end
		end
	end)

	t.test("property: random plain values round-trip and are order independent", function()
		local rng = Rng.new(expect.isOk(Seed.fromHex("0badc0de0badc0de")))
		local function randomValue(depth: number): any
			local pick = rng:nextInt(1, if depth >= 3 then 5 else 7)
			if pick == 1 then
				return rng:chancePermille(500)
			elseif pick == 2 then
				return rng:nextInt(-100000, 100000)
			elseif pick == 3 then
				return rng:nextRange(-1000, 1000)
			elseif pick == 4 then
				local length = rng:nextInt(0, 10)
				local chars = table.create(length)
				for i = 1, length do
					chars[i] = string.char(rng:nextInt(0, 255))
				end
				return table.concat(chars)
			elseif pick == 5 then
				return rng:nextInt(0, 3) -- small ints keep collisions in maps interesting
			elseif pick == 6 then
				local list = {}
				for i = 1, rng:nextInt(0, 5) do
					list[i] = randomValue(depth + 1)
				end
				return list
			end
			local map: { [string]: any } = {}
			for _ = 1, rng:nextInt(1, 5) do
				local keyLength = rng:nextInt(0, 6)
				local key = table.create(keyLength)
				for i = 1, keyLength do
					key[i] = string.char(rng:nextInt(97, 100))
				end
				map[table.concat(key)] = randomValue(depth + 1)
			end
			return map
		end
		for _ = 1, 300 do
			local value = randomValue(0)
			local encoded = expect.isOk(CanonicalEncode.encode(value))
			local decoded = expect.isOk(CanonicalEncode.decode(encoded))
			expect.deepEqual(decoded, value)
			expect.equal(expect.isOk(CanonicalEncode.encode(decoded)), encoded)
		end
	end)
end
