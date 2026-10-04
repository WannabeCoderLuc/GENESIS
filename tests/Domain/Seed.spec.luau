--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local ErrorCodes = require(Paths.core("ErrorCodes"))
local Seed = require(Paths.domain("Seed"))
local Vectors = require(Paths.vector("SeedVectorsV1"))
local Versions = require(Paths.domain("Versions"))

local function version(n: number): Versions.GeneratorVersion
	return n :: any
end

return function(t: TestContext.TestContext)
	local expect = t.expect

	local function seedOf(hex: string): Seed.Seed
		return expect.isOk(Seed.fromHex(hex))
	end

	-- Every (parent, namespace, stableId, generatorVersion) -> child pair equals the independent reference.
	t.test("derive matches reference vectors", function()
		for _, case in ipairs(Vectors.derive) do
			local child = expect.isOk(Seed.derive(seedOf(case.parentHex), case.namespace, case.stableId, version(case.generatorVersion)))
			expect.equal(Seed.toHex(child), case.childHex, case.namespace .. "/" .. case.stableId)
		end
	end)

	t.test("fromText matches reference vectors", function()
		for _, case in ipairs(Vectors.fromText) do
			expect.equal(Seed.toHex(expect.isOk(Seed.fromText(case.purpose, case.text))), case.hex)
		end
	end)

	-- Seven-level address walk (epoch .. subobject): every intermediate seed matches, and deriveAlongPath agrees.
	t.test("deriveAlongPath matches stepwise reference derivation", function()
		for _, case in ipairs(Vectors.paths) do
			local root = seedOf(case.rootHex)
			local current = root
			local path = {}
			for _, step in ipairs(case.steps) do
				current = expect.isOk(Seed.derive(current, step.namespace, step.stableId, version(case.generatorVersion)))
				expect.equal(Seed.toHex(current), step.hex, step.namespace)
				table.insert(path, { namespace = step.namespace, stableId = step.stableId })
			end
			local viaPath = expect.isOk(Seed.deriveAlongPath(root, path, version(case.generatorVersion)))
			expect.equal(Seed.toHex(viaPath), case.steps[#case.steps].hex)
		end
	end)

	-- Identical input produces identical output, across fresh values and repeated calls.
	t.test("identical input produces identical output", function()
		local parent = seedOf("0123456789abcdef")
		local first = expect.isOk(Seed.derive(parent, "sector", "S-1", version(1)))
		for _ = 1, 100 do
			local again = expect.isOk(Seed.derive(seedOf("0123456789abcdef"), "sector", "S-1", version(1)))
			expect.truthy(Seed.equals(first, again))
		end
	end)

	-- Iteration order must never matter: derive 300 siblings forward, reversed and in a scrambled order.
	t.test("iteration order does not alter derived seeds", function()
		local parent = seedOf("deadbeefcafef00d")
		local ids = {}
		for i = 1, 300 do
			ids[i] = "S-" .. i
		end
		local function deriveAll(order: { number }): { [string]: string }
			local out: { [string]: string } = {}
			for _, index in ipairs(order) do
				out[ids[index]] = Seed.toHex(expect.isOk(Seed.derive(parent, "sector", ids[index], version(1))))
			end
			return out
		end
		local forward, reverse, scrambled = {}, {}, {}
		for i = 1, 300 do
			forward[i] = i
			reverse[i] = 301 - i
			scrambled[i] = ((i * 137) % 300) + 1 -- 137 is coprime with 300, so this is a permutation
		end
		local a, b, c = deriveAll(forward), deriveAll(reverse), deriveAll(scrambled)
		expect.deepEqual(a, b)
		expect.deepEqual(a, c)
	end)

	-- A different value in ANY input field must change the child (no field is ignored).
	t.test("every input field influences the child seed", function()
		local parent = seedOf("0123456789abcdef")
		local base = Seed.toHex(expect.isOk(Seed.derive(parent, "sector", "S-1", version(1))))
		expect.notEqual(Seed.toHex(expect.isOk(Seed.derive(seedOf("0123456789abcdee"), "sector", "S-1", version(1)))), base)
		expect.notEqual(Seed.toHex(expect.isOk(Seed.derive(parent, "system", "S-1", version(1)))), base)
		expect.notEqual(Seed.toHex(expect.isOk(Seed.derive(parent, "sector", "S-2", version(1)))), base)
		expect.notEqual(Seed.toHex(expect.isOk(Seed.derive(parent, "sector", "S-1", version(2)))), base)
	end)

	-- Stress corpus: 2000 sibling seeds, no collisions, digest equals the reference digest.
	t.test("sibling stress corpus has no collisions and matches the reference digest", function()
		local stress = Vectors.stress
		local parent = seedOf(stress.parentHex)
		local Hash64 = require(Paths.domain("Hash64"))
		local Uint64 = require(Paths.domain("Uint64"))
		local seen: { [string]: boolean } = {}
		local hi, lo = Hash64.OFFSET_HI, Hash64.OFFSET_LO
		for i = 0, stress.count - 1 do
			local child = Seed.toHex(expect.isOk(Seed.derive(parent, stress.namespace, stress.idPrefix .. i, version(stress.generatorVersion))))
			expect.falsy(seen[child], "collision at " .. i)
			seen[child] = true
			hi, lo = Hash64.absorbString(hi, lo, child)
		end
		hi, lo = Hash64.fmix(hi, lo)
		expect.equal(Uint64.toHex(hi, lo), stress.digestHex)
	end)

	t.test("hex form is canonical and round-trips", function()
		expect.equal(Seed.toHex(seedOf("0000000000000000")), "0000000000000000")
		local seed = expect.isOk(Seed.fromLanes(0xDEADBEEF, 0x00000001))
		expect.equal(Seed.toHex(seed), "deadbeef00000001")
		expect.truthy(Seed.equals(seed, seedOf("deadbeef00000001")))
		for _, bad in ipairs({ "", "DEADBEEF00000001", "deadbeef0000000", "deadbeef000000011", "zzzzzzzzzzzzzzzz" }) do
			expect.isErr(Seed.fromHex(bad), ErrorCodes.SEED_INVALID_HEX, bad)
		end
		expect.isErr(Seed.fromHex(12345 :: any), ErrorCodes.SEED_INVALID_HEX)
	end)

	t.test("fromLanes rejects non-uint32 lanes", function()
		for _, bad in ipairs({ -1, 4294967296, 1.5, 0 / 0, math.huge }) do
			expect.isErr(Seed.fromLanes(bad, 0), ErrorCodes.SEED_INVALID_LANE)
			expect.isErr(Seed.fromLanes(0, bad), ErrorCodes.SEED_INVALID_LANE)
		end
		expect.isErr(Seed.fromLanes("1" :: any, 0), ErrorCodes.SEED_INVALID_LANE)
	end)

	-- Hostile namespace / id text is rejected before it can reach the hash.
	t.test("derive rejects invalid namespaces and stable ids", function()
		local parent = seedOf("0123456789abcdef")
		for _, bad in ipairs({ "", "Sector", "1sector", "sec tor", "sec/tor", "sec:tor", string.rep("a", 33), "s\u{E9}ctor" }) do
			expect.isErr(Seed.derive(parent, bad, "S-1", version(1)), ErrorCodes.SEED_INVALID_NAMESPACE, "namespace " .. bad)
		end
		for _, bad in ipairs({ "", "S 1", "S/1", "S:1", string.rep("x", 65), "S\u{E9}", "S\n1", "S\0" }) do
			expect.isErr(Seed.derive(parent, "sector", bad, version(1)), ErrorCodes.SEED_INVALID_STABLE_ID, "id " .. bad)
		end
		expect.isErr(Seed.fromText("Bad Purpose", "x"), ErrorCodes.SEED_INVALID_NAMESPACE)
	end)

	t.test("derived seeds are immutable", function()
		local seed = seedOf("0123456789abcdef")
		expect.throws(function()
			(seed :: any).lo = 5
		end)
	end)

	t.test("deriveAlongPath surfaces the failing segment", function()
		local root = seedOf("0123456789abcdef")
		expect.isErr(
			Seed.deriveAlongPath(root, { { namespace = "epoch", stableId = "E1" }, { namespace = "cluster", stableId = "bad id" } }, version(1)),
			ErrorCodes.SEED_INVALID_STABLE_ID
		)
		-- Empty path returns the root unchanged.
		expect.truthy(Seed.equals(expect.isOk(Seed.deriveAlongPath(root, {}, version(1))), root))
	end)
end
