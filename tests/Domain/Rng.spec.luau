--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local Hash64 = require(Paths.domain("Hash64"))
local Rng = require(Paths.domain("Rng"))
local Seed = require(Paths.domain("Seed"))
local Uint64 = require(Paths.domain("Uint64"))
local Vectors = require(Paths.vector("RngVectorsV1"))

return function(t: TestContext.TestContext)
	local expect = t.expect

	local function rngFor(hex: string): Rng.Rng
		return Rng.new(expect.isOk(Seed.fromHex(hex)))
	end

	t.test("next32 matches the reference stream", function()
		for _, case in ipairs(Vectors.first32) do
			local rng = rngFor(case.seedHex)
			for index, expected in ipairs(case.values) do
				expect.equal(rng:next32(), expected, case.seedHex .. " draw " .. index)
			end
		end
	end)

	t.test("nextU53 matches the reference and nextUnit is exactly numerator / 2^53", function()
		for _, case in ipairs(Vectors.u53) do
			local rng = rngFor(case.seedHex)
			local unitRng = rngFor(case.seedHex)
			for index, expected in ipairs(case.values) do
				expect.equal(rng:nextU53(), expected, case.seedHex .. " u53 " .. index)
				expect.equal(unitRng:nextUnit() * 9007199254740992, expected, "unit " .. index)
			end
		end
	end)

	-- Inclusive integer ranges, including 1 value, negatives, exactly 2^32 and >2^32 (53-bit path).
	t.test("nextInt matches the reference for every range class", function()
		for _, case in ipairs(Vectors.ints) do
			local rng = rngFor(case.seedHex)
			for index, expected in ipairs(case.values) do
				expect.equal(rng:nextInt(case.lo, case.hi), expected, string.format("%s [%d,%d] #%d", case.seedHex, case.lo, case.hi, index))
			end
		end
	end)

	-- 10,000 consecutive draws collapse into one digest: any single-bit divergence anywhere fails.
	t.test("10,000-draw digests match the reference", function()
		for _, case in ipairs(Vectors.digests) do
			local rng = rngFor(case.seedHex)
			local hi, lo = Hash64.OFFSET_HI, Hash64.OFFSET_LO
			for _ = 1, case.count do
				hi, lo = Hash64.absorbU32(hi, lo, rng:next32())
			end
			hi, lo = Hash64.fmix(hi, lo)
			expect.equal(Uint64.toHex(hi, lo), case.digestHex, case.seedHex)
		end
	end)

	t.test("shuffle and chancePermille match the reference", function()
		for _, case in ipairs(Vectors.shuffles) do
			expect.deepEqual(rngFor(case.seedHex):shuffle(table.clone(case.input)), case.output, case.seedHex)
		end
		for _, case in ipairs(Vectors.chances) do
			local rng = rngFor(case.seedHex)
			for index, expected in ipairs(case.values) do
				expect.equal(rng:chancePermille(case.chancePermille), expected, case.seedHex .. " #" .. index)
			end
		end
	end)

	-- Identical input produces identical output: two generators from one seed stay in lock-step.
	t.test("identical seeds produce identical streams", function()
		local a, b = rngFor("0123456789abcdef"), rngFor("0123456789abcdef")
		for _ = 1, 2000 do
			expect.equal(a:next32(), b:next32())
		end
	end)

	t.test("saveState / fromState resume exactly where the stream left off", function()
		for _, case in ipairs(Vectors.resumes) do
			local rng = rngFor(case.seedHex)
			for _ = 1, case.skip do
				rng:next32()
			end
			local resumed = Rng.fromState(rng:saveState())
			for index, expected in ipairs(case.next) do
				expect.equal(resumed:next32(), expected, "resumed " .. index)
				expect.equal(rng:next32(), expected, "original " .. index)
			end
		end
	end)

	-- Values remain finite and inside the declared bounds, across many seeds and draws.
	t.test("outputs are finite and within declared bounds", function()
		local meta = rngFor("deadbeefcafef00d")
		for _ = 1, 40 do
			local seed = expect.isOk(Seed.fromLanes(meta:next32(), meta:next32()))
			local rng = Rng.new(seed)
			for _ = 1, 250 do
				local u32 = rng:next32()
				expect.between(u32, 0, 4294967295)
				local unit = rng:nextUnit()
				expect.finite(unit)
				expect.truthy(unit >= 0 and unit < 1, "unit " .. unit)
				local ranged = rng:nextRange(-3.5, 9.25)
				expect.between(ranged, -3.5, 9.25)
				local int = rng:nextInt(-7, 11)
				expect.between(int, -7, 11)
				expect.equal(int, math.floor(int))
				local wide = rng:nextInt(0, 4294967296)
				expect.between(wide, 0, 4294967296)
				local huge = rng:nextInt(-4503599627370496, 4503599627370495)
				expect.between(huge, -4503599627370496, 4503599627370495)
				expect.equal(huge, math.floor(huge))
			end
		end
	end)

	-- Rejection sampling: every value of a small range appears, with roughly uniform frequency.
	t.test("nextInt is unbiased over a small range", function()
		local rng = rngFor("0123456789abcdef")
		local counts = { 0, 0, 0, 0, 0, 0 }
		local draws = 60000
		for _ = 1, draws do
			local face = rng:nextInt(1, 6)
			counts[face] += 1
		end
		for face = 1, 6 do
			expect.near(counts[face], draws / 6, draws * 0.02, "face " .. face)
		end
	end)

	t.test("nextInt with a single-value range consumes no draw", function()
		local a, b = rngFor("0123456789abcdef"), rngFor("0123456789abcdef")
		expect.equal(a:nextInt(5, 5), 5)
		expect.equal(a:next32(), b:next32())
	end)

	t.test("misuse raises instead of silently returning garbage", function()
		local rng = rngFor("0123456789abcdef")
		expect.throws(function()
			rng:nextInt(5, 4)
		end)
		expect.throws(function()
			rng:nextInt(1.5, 3)
		end)
		expect.throws(function()
			rng:nextRange(0 / 0, 1)
		end)
		expect.throws(function()
			rng:nextRange(2, 1)
		end)
		expect.throws(function()
			rng:chancePermille(1001)
		end)
		expect.throws(function()
			rng:nextInt(0, 9007199254740992)
		end)
	end)

	t.test("shuffle keeps the same multiset of elements", function()
		local rng = rngFor("8000000080000000")
		local list = {}
		for i = 1, 200 do
			list[i] = i
		end
		rng:shuffle(list)
		local seen = {}
		for _, value in ipairs(list) do
			expect.falsy(seen[value], "duplicate " .. value)
			seen[value] = true
		end
		expect.equal(#list, 200)
	end)
end
