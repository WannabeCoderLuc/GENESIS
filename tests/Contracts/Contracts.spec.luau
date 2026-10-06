--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local ErrorCodes = require(Paths.core("ErrorCodes"))
local UniverseAddressV1 = require(Paths.contract("UniverseAddressV1"))
local PlayerProfileV1 = require(Paths.contract("PlayerProfileV1"))
local UniverseManifestV1 = require(Paths.contract("UniverseManifestV1"))
local CommandEnvelopeV1 = require(Paths.contract("CommandEnvelopeV1"))
local Rng = require(Paths.domain("Rng"))
local Seed = require(Paths.domain("Seed"))

return function(t: TestContext.TestContext)
	local expect = t.expect

	t.test("UniverseAddressV1 parsing and formatting round-trips", function()
		local parsed = expect.isOk(UniverseAddressV1.parse("epoch:E1/cluster:C2"))
		expect.equal(#parsed.elements, 2)
		expect.equal(parsed.elements[1].namespace, "epoch")
		expect.equal(parsed.elements[1].stableId, "E1")
		expect.equal(UniverseAddressV1.format(parsed), "epoch:E1/cluster:C2")
		
		expect.isErr(UniverseAddressV1.parse("epoch:E1/cluster:C2/galaxy:G3/sector:S4/system:S5/body:B6/subobject:O7/extra:E8"), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)
		expect.isErr(UniverseAddressV1.parse("bad namespace:ID"), ErrorCodes.ADDRESS_INVALID)
	end)

	t.test("PlayerProfileV1 validates correctly", function()
		local valid = {
			schemaVersion = 1,
			userId = 12345,
			creationTime = 1000000,
			lastSaveTime = 1000000,
		}
		expect.isOk(PlayerProfileV1.validate(valid))
		
		local invalidSchema = table.clone(valid)
		invalidSchema.schemaVersion = 2
		expect.isErr(PlayerProfileV1.validate(invalidSchema), ErrorCodes.SCHEMA_INVALID)

		local invalidTime = table.clone(valid)
		invalidTime.creationTime = math.huge
		expect.isErr(PlayerProfileV1.validate(invalidTime), ErrorCodes.SCHEMA_INVALID)
	end)

	t.test("UniverseManifestV1 validates correctly", function()
		local valid = {
			schemaVersion = 1,
			universeId = "U-123",
			ownerId = 12345,
			generatorVersion = 1,
			creationTime = 1000000,
			seedHex = "0123456789abcdef",
		}
		expect.isOk(UniverseManifestV1.validate(valid))
		
		local badSeed = table.clone(valid)
		badSeed.seedHex = "bad-seed"
		expect.isErr(UniverseManifestV1.validate(badSeed), ErrorCodes.SCHEMA_INVALID)

		local badTime = table.clone(valid)
		badTime.creationTime = -math.huge
		expect.isErr(UniverseManifestV1.validate(badTime), ErrorCodes.SCHEMA_INVALID)
	end)

	t.test("CommandEnvelopeV1 schema boundaries and limits", function()
		local envelope = {
			schemaVersion = 1,
			commandId = "CMD-12345678",
			universeId = "U-1",
			kind = "Ignition",
			payload = { a = 1, b = "hello" },
			timestamp = 12345,
		}
		expect.isOk(CommandEnvelopeV1.validate(envelope))
		
		-- Test depth
		local deepPayload = {}
		local current = deepPayload
		for _ = 1, 17 do
			current.next = {}
			current = current.next
		end
		local envelopeDeep = table.clone(envelope)
		envelopeDeep.payload = deepPayload
		expect.isErr(CommandEnvelopeV1.validate(envelopeDeep), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)
		
		-- Test broad
		local broadPayload = {}
		for i = 1, 1025 do
			broadPayload[tostring(i)] = true
		end
		local envelopeBroad = table.clone(envelope)
		envelopeBroad.payload = broadPayload
		expect.isErr(CommandEnvelopeV1.validate(envelopeBroad), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)
		
		-- Test string size
		local largeString = string.rep("x", 5000)
		local envelopeLargeString = table.clone(envelope)
		envelopeLargeString.payload = { text = largeString }
		expect.isErr(CommandEnvelopeV1.validate(envelopeLargeString), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)

		-- Test invalid types (function)
		local envelopeFunc = table.clone(envelope)
		envelopeFunc.payload = { fn = function() end }
		expect.isErr(CommandEnvelopeV1.validate(envelopeFunc), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)
		
		-- Test invalid keys (userdata)
		local envelopeUserdataKey = table.clone(envelope)
		local ud = newproxy()
		envelopeUserdataKey.payload = { [ud] = "val" }
		expect.isErr(CommandEnvelopeV1.validate(envelopeUserdataKey), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)

		-- Test math.huge timestamp
		local envelopeHuge = table.clone(envelope)
		envelopeHuge.timestamp = math.huge
		expect.isErr(CommandEnvelopeV1.validate(envelopeHuge), ErrorCodes.SCHEMA_INVALID)

	end)

	t.test("test_cycle_rejection", function()
		local envelope = {
			schemaVersion = 1,
			commandId = "CMD-12345678",
			universeId = "U-1",
			kind = "Ignition",
			payload = {},
			timestamp = 12345,
		}
		local cyclicPayload = {}
		cyclicPayload.self = cyclicPayload
		local envelopeCyclic = table.clone(envelope)
		envelopeCyclic.payload = cyclicPayload
		expect.isErr(CommandEnvelopeV1.validate(envelopeCyclic), ErrorCodes.SCHEMA_LIMIT_EXCEEDED)
	end)

	t.test("fuzz corpus: random noise on contracts is rejected safely", function()
		local rng = Rng.new(expect.isOk(Seed.fromHex("f000c00000000000")))
		
		local function generateRandomValue(depth: number): any
			if depth > 4 then return "leaf" end
			local pick = rng:nextInt(1, 6)
			if pick == 1 then return rng:nextInt(0, 100)
			elseif pick == 2 then return "str" .. rng:nextInt(1, 10)
			elseif pick == 3 then return rng:chancePermille(500)
			elseif pick == 4 then return nil
			else
				local node = {}
				for _ = 1, rng:nextInt(1, 4) do
					node["k" .. rng:nextInt(1, 10)] = generateRandomValue(depth + 1)
				end
				return node
			end
		end

		for _ = 1, 1000 do
			local val = generateRandomValue(1)
			-- Validation must not throw, only return Result
			local ok = pcall(PlayerProfileV1.validate, val)
			expect.truthy(ok, "PlayerProfileV1 threw on fuzz input")
			local ok2 = pcall(UniverseManifestV1.validate, val)
			expect.truthy(ok2, "UniverseManifestV1 threw on fuzz input")
			local ok3 = pcall(CommandEnvelopeV1.validate, val)
			expect.truthy(ok3, "CommandEnvelopeV1 threw on fuzz input")
			local ok4 = pcall(UniverseAddressV1.validate, val)
			expect.truthy(ok4, "UniverseAddressV1 threw on fuzz input")
		end
	end)
end
