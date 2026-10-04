--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local Rng = require(Paths.domain("Rng"))
local RngStreams = require(Paths.domain("RngStreams"))
local Seed = require(Paths.domain("Seed"))
local Vectors = require(Paths.vector("RngVectorsV1"))
local Versions = require(Paths.domain("Versions"))

local function version(n: number): Versions.GeneratorVersion
	return n :: any
end

local CANONICAL = { "morphology", "positions", "composition", "anomalies" }
local COSMETIC = { "names", "visual" }

return function(t: TestContext.TestContext)
	local expect = t.expect

	local function seedOf(hex: string): Seed.Seed
		return expect.isOk(Seed.fromHex(hex))
	end

	local function accessorFor(set: RngStreams.StreamSet, name: string): RngStreams.StreamAccessor
		if RngStreams.REGISTRY[name] == "canonical" then
			return set.canonical
		end
		return set.cosmetic
	end

	t.test("stream seeds and first draws match the reference", function()
		for _, case in ipairs(Vectors.streams) do
			local set = RngStreams.new(seedOf(case.baseHex), version(case.generatorVersion))
			local accessor = accessorFor(set, case.name)
			expect.equal(Seed.toHex(accessor:seedOf(case.name)), case.seedHex, case.name)
			local rng = accessor:get(case.name)
			for index, expected in ipairs(case.first) do
				expect.equal(rng:next32(), expected, case.name .. " #" .. index)
			end
		end
	end)

	-- THE core isolation guarantee: hammering cosmetic streams cannot change one canonical value.
	t.test("unrelated streams do not affect one another", function()
		local base = seedOf("0123456789abcdef")
		local quiet = RngStreams.new(base, version(1))
		local noisy = RngStreams.new(base, version(1))

		local expected = {}
		for _, name in ipairs(CANONICAL) do
			local rng = quiet.canonical:get(name)
			local values = {}
			for i = 1, 50 do
				values[i] = rng:next32()
			end
			expected[name] = values
		end

		-- Interleave massive cosmetic consumption with canonical draws on the other set.
		local visual = noisy.cosmetic:get("visual")
		local names = noisy.cosmetic:get("names")
		for _, name in ipairs(CANONICAL) do
			local rng = noisy.canonical:get(name)
			for i = 1, 50 do
				for _ = 1, i * 3 do
					visual:next32()
					names:nextUnit()
				end
				expect.equal(rng:next32(), expected[name][i], name .. " draw " .. i)
			end
		end
	end)

	t.test("canonical streams do not affect one another either", function()
		local base = seedOf("deadbeefcafef00d")
		local reference = RngStreams.new(base, version(1))
		local expected = {}
		for i = 1, 100 do
			expected[i] = reference.canonical:get("positions"):next32()
		end
		local disturbed = RngStreams.new(base, version(1))
		local positions = disturbed.canonical:get("positions")
		for i = 1, 100 do
			disturbed.canonical:get("composition"):next32()
			disturbed.canonical:get("morphology"):next32()
			expect.equal(positions:next32(), expected[i])
		end
	end)

	-- Iteration order: requesting streams in any order yields the same per-stream values.
	t.test("stream access order does not alter any stream", function()
		local base = seedOf("0123456789abcdef")
		local function firstDraws(order: { string }): { [string]: number }
			local set = RngStreams.new(base, version(2))
			local out = {}
			for _, name in ipairs(order) do
				out[name] = accessorFor(set, name):get(name):next32()
			end
			return out
		end
		local all = { "morphology", "positions", "composition", "anomalies", "names", "visual" }
		local reversed = {}
		for i = #all, 1, -1 do
			table.insert(reversed, all[i])
		end
		local shuffled = { "composition", "visual", "morphology", "names", "anomalies", "positions" }
		expect.deepEqual(firstDraws(all), firstDraws(reversed))
		expect.deepEqual(firstDraws(all), firstDraws(shuffled))
	end)

	t.test("identical (seed, version) gives identical streams; a version bump changes them", function()
		local base = seedOf("0123456789abcdef")
		local a = RngStreams.new(base, version(1)).canonical:get("positions")
		local b = RngStreams.new(base, version(1)).canonical:get("positions")
		local c = RngStreams.new(base, version(2)).canonical:get("positions")
		local sameCount, differentCount = 0, 0
		for _ = 1, 20 do
			local va, vb, vc = a:next32(), b:next32(), c:next32()
			if va == vb then
				sameCount += 1
			end
			if va ~= vc then
				differentCount += 1
			end
		end
		expect.equal(sameCount, 20)
		expect.truthy(differentCount >= 19)
	end)

	t.test("get returns the same continuing stream object per name", function()
		local set = RngStreams.new(seedOf("0123456789abcdef"), version(1))
		local first = set.canonical:get("positions")
		local second = set.canonical:get("positions")
		expect.truthy(first == second)
	end)

	-- Presentation code gets only set.cosmetic and structurally cannot reach a canonical stream.
	t.test("accessors refuse streams of the other class and unregistered names", function()
		local set = RngStreams.new(seedOf("0123456789abcdef"), version(1))
		for _, name in ipairs(CANONICAL) do
			expect.throws(function()
				set.cosmetic:get(name)
			end, "not available from the cosmetic accessor")
		end
		for _, name in ipairs(COSMETIC) do
			expect.throws(function()
				set.canonical:get(name)
			end, "not available from the canonical accessor")
		end
		expect.throws(function()
			set.canonical:get("improvised")
		end, "not registered")
	end)

	t.test("registry is frozen and every stream is classified", function()
		expect.throws(function()
			(RngStreams.REGISTRY :: any).extra = "canonical"
		end)
		local count = 0
		for _, class in pairs(RngStreams.REGISTRY) do
			expect.truthy(class == "canonical" or class == "cosmetic")
			count += 1
		end
		expect.equal(count, #CANONICAL + #COSMETIC)
	end)

	t.test("stream draws stay finite and bounded", function()
		local set = RngStreams.new(seedOf("ffffffffffffffff"), version(1))
		for _, name in ipairs(CANONICAL) do
			local rng: Rng.Rng = set.canonical:get(name)
			for _ = 1, 500 do
				local unit = rng:nextUnit()
				expect.truthy(unit >= 0 and unit < 1)
			end
		end
	end)
end
