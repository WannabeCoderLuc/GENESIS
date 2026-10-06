--!strict
local Paths = require(script.Parent.Parent.Support.Paths)
local TestContext = require(script.Parent.Parent.Support.TestContext)
local FirstStarStellarModel = require(Paths.domain("FirstStarStellarModel"))
local Rng = require(Paths.domain("Rng"))
local Seed = require(Paths.domain("Seed"))

return function(t: TestContext.TestContext)
	local function createRng()
		local seedResult = Seed.fromHex("1234567890abcdef")
		return Rng.new(seedResult.value)
	end
	
	t.test("generates a deterministic star state", function()
		local rng = createRng()
		local state = FirstStarStellarModel.generate(rng)
		
		t.expect.equal(state.mass >= 0.5 and state.mass <= 2.0, true)
		t.expect.equal(state.temperature > 2000, true)
		t.expect.equal(type(state.spectralClass), "string")
		t.expect.equal(state.luminosity > 0, true)
		t.expect.equal(state.radius > 0, true)
		t.expect.equal(state.age > 0, true)
		t.expect.equal(state.lifespan > 0, true)
		t.expect.equal(state.age < state.lifespan, true)
	end)
	
	t.test("determines correct spectral class based on temperature limits", function()
		local rng = createRng()
		for i = 1, 10 do
			local state = FirstStarStellarModel.generate(rng)
			if state.temperature >= 6000 and state.temperature < 7500 then
				t.expect.equal(state.spectralClass, "F")
			elseif state.temperature >= 5200 and state.temperature < 6000 then
				t.expect.equal(state.spectralClass, "G")
			elseif state.temperature >= 3700 and state.temperature < 5200 then
				t.expect.equal(state.spectralClass, "K")
			end
		end
	end)
end
