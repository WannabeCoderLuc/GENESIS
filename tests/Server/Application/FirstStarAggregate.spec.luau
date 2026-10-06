--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local FirstStarAggregate = require(ServerScriptService.Server.Application.FirstStarAggregate)
local Seed = require(ReplicatedStorage.Shared.Domain.Seed)
local ErrorCodes = require(ReplicatedStorage.Shared.Core.ErrorCodes)

return function(t: any)
	local function createSeed()
		return Seed.fromHex("1234567890abcdef").value
	end
	
	t.test("handleIgnition sets state and returns generated star", function()
		local aggregate = FirstStarAggregate.new()
		local seed = createSeed()
		local command = { kind = "Ignition" }
		
		local result = aggregate:handleIgnition(command :: any, seed, 1000)
		t.expect.truthy(result.ok)
		
		if result.ok then
			t.expect.equal(result.value.schemaVersion, 1)
			t.expect.equal(result.value.ignitedAt, 1000)
			t.expect.truthy(result.value.mass > 0)
			t.expect.truthy(aggregate.state ~= nil)
			if aggregate.state then
				t.expect.equal(aggregate.state.ignitedAt, 1000)
			end
		end
	end)
	
	t.test("handleIgnition fails if already ignited", function()
		local aggregate = FirstStarAggregate.new()
		local seed = createSeed()
		local command = { kind = "Ignition" }
		
		local firstResult = aggregate:handleIgnition(command :: any, seed, 1000)
		t.expect.truthy(firstResult.ok)
		
		local secondResult = aggregate:handleIgnition(command :: any, seed, 2000)
		t.expect.falsy(secondResult.ok)
		if not secondResult.ok then
			t.expect.equal(secondResult.code, ErrorCodes.FIRST_STAR_ALREADY_IGNITED)
		end
	end)
end
