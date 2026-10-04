--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local Uint64 = require(Paths.domain("Uint64"))
local Vectors = require(Paths.vector("UintVectorsV1"))

return function(t: TestContext.TestContext)
	local expect = t.expect

	-- 32x32 -> low 32 bits agrees with the BigInt reference on edge and pseudo-random operands.
	t.test("mul32 matches reference", function()
		for _, case in ipairs(Vectors.mul32) do
			expect.equal(Uint64.mul32(case.a, case.b), case.result, string.format("mul32(%d,%d)", case.a, case.b))
		end
	end)

	-- 32x32 -> full 64-bit product (hi, lo).
	t.test("mulWide32 matches reference", function()
		for _, case in ipairs(Vectors.mulWide32) do
			local hi, lo = Uint64.mulWide32(case.a, case.b)
			expect.equal(hi, case.hi, string.format("hi of %d*%d", case.a, case.b))
			expect.equal(lo, case.lo, string.format("lo of %d*%d", case.a, case.b))
		end
	end)

	-- 64-bit multiply modulo 2^64.
	t.test("mul matches reference", function()
		for _, case in ipairs(Vectors.mul) do
			local hi, lo = Uint64.mul(case.aHi, case.aLo, case.bHi, case.bLo)
			expect.equal(hi, case.hi, "hi")
			expect.equal(lo, case.lo, "lo")
		end
	end)

	-- 64-bit add with carry, wrapping at 2^64.
	t.test("add matches reference", function()
		for _, case in ipairs(Vectors.add) do
			local hi, lo = Uint64.add(case.aHi, case.aLo, case.bHi, case.bLo)
			expect.equal(hi, case.hi, "hi")
			expect.equal(lo, case.lo, "lo")
		end
	end)

	t.test("xor matches reference", function()
		for _, case in ipairs(Vectors.xor) do
			local hi, lo = Uint64.xor(case.aHi, case.aLo, case.bHi, case.bLo)
			expect.equal(hi, case.hi, "hi")
			expect.equal(lo, case.lo, "lo")
		end
	end)

	-- Logical right shift for every boundary class (0, <32, 32, >32, 63).
	t.test("shr matches reference", function()
		for _, case in ipairs(Vectors.shr) do
			local hi, lo = Uint64.shr(case.hi, case.lo, case.n)
			expect.equal(hi, case.outHi, string.format("hi of shr %d", case.n))
			expect.equal(lo, case.outLo, string.format("lo of shr %d", case.n))
		end
	end)

	t.test("all results stay inside uint32 lanes", function()
		for _, case in ipairs(Vectors.mul) do
			local hi, lo = Uint64.mul(case.aHi, case.aLo, case.bHi, case.bLo)
			expect.between(hi, 0, 4294967295)
			expect.between(lo, 0, 4294967295)
			expect.equal(hi, math.floor(hi))
			expect.equal(lo, math.floor(lo))
		end
	end)

	-- Hex form is exactly 16 lowercase digits, parses back, and rejects every other shape.
	t.test("hex round-trips and rejects malformed text", function()
		expect.equal(Uint64.toHex(0, 0), "0000000000000000")
		expect.equal(Uint64.toHex(0xFFFFFFFF, 0xFFFFFFFF), "ffffffffffffffff")
		expect.equal(Uint64.toHex(0x01234567, 0x89ABCDEF), "0123456789abcdef")
		local hi, lo = Uint64.fromHex("0123456789abcdef")
		expect.equal(hi, 0x01234567)
		expect.equal(lo, 0x89ABCDEF)
		for _, bad in ipairs({ "", "0123456789ABCDEF", "0123456789abcde", "0123456789abcdef0", "0123456789abcdeg", "0x23456789abcdef" }) do
			local badHi, badLo = Uint64.fromHex(bad)
			expect.equal(badHi, nil, "fromHex(" .. bad .. ")")
			expect.equal(badLo, nil, "fromHex(" .. bad .. ")")
		end
	end)
end
