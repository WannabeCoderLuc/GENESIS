--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local Hash64 = require(Paths.domain("Hash64"))
local SplitMix64 = require(Paths.domain("SplitMix64"))
local Uint64 = require(Paths.domain("Uint64"))
local Vectors = require(Paths.vector("HashVectorsV1"))

return function(t: TestContext.TestContext)
	local expect = t.expect

	-- Includes the published FNV-1a 64 vectors ("", "a", "foobar") plus binary inputs.
	t.test("FNV-1a 64 absorption matches reference", function()
		for _, case in ipairs(Vectors.fnv1a64) do
			local hi, lo = Hash64.absorbString(Hash64.OFFSET_HI, Hash64.OFFSET_LO, case.input)
			expect.equal(Uint64.toHex(hi, lo), case.hex, "fnv(" .. string.sub(case.input, 1, 12) .. ")")
		end
	end)

	t.test("fmix64 finalizer matches reference", function()
		for _, case in ipairs(Vectors.fmix64) do
			local inHi, inLo = Uint64.fromHex(case.inputHex)
			local hi, lo = Hash64.fmix(inHi :: number, inLo :: number)
			expect.equal(Uint64.toHex(hi, lo), case.outputHex, "fmix(" .. case.inputHex .. ")")
		end
	end)

	t.test("hashString (FNV-1a + fmix64) matches reference", function()
		for _, case in ipairs(Vectors.hashString) do
			local hi, lo = Hash64.hashString(case.input)
			expect.equal(Uint64.toHex(hi, lo), case.hex)
		end
	end)

	-- Includes the published SplitMix64 sequence from state 0.
	t.test("SplitMix64 sequence matches reference", function()
		for _, case in ipairs(Vectors.splitmix64) do
			local stateHi, stateLo = Uint64.fromHex(case.seedHex)
			local hi, lo = stateHi :: number, stateLo :: number
			for index, expected in ipairs(case.outputs) do
				local outHi, outLo
				hi, lo, outHi, outLo = SplitMix64.next(hi, lo)
				expect.equal(Uint64.toHex(hi, lo), expected.stateHex, "state " .. index)
				expect.equal(Uint64.toHex(outHi, outLo), expected.outHex, "output " .. index)
			end
		end
	end)

	-- ("ab","c") and ("a","bc") would collide without length prefixes.
	t.test("absorbField is unambiguous across field boundaries", function()
		local hi1, lo1 = Hash64.absorbField(Hash64.OFFSET_HI, Hash64.OFFSET_LO, "ab")
		hi1, lo1 = Hash64.absorbField(hi1, lo1, "c")
		local hi2, lo2 = Hash64.absorbField(Hash64.OFFSET_HI, Hash64.OFFSET_LO, "a")
		hi2, lo2 = Hash64.absorbField(hi2, lo2, "bc")
		expect.truthy(hi1 ~= hi2 or lo1 ~= lo2)
	end)

	t.test("hashing is pure: same input, same output, repeatedly", function()
		local firstHi, firstLo = Hash64.hashString("repeatable")
		for _ = 1, 50 do
			local hi, lo = Hash64.hashString("repeatable")
			expect.equal(hi, firstHi)
			expect.equal(lo, firstLo)
		end
	end)
end
