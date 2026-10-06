--!strict
local Rng = require(script.Parent.Rng)
type Rng = Rng.Rng
export type SpectralClass = "O" | "B" | "A" | "F" | "G" | "K" | "M"

export type StellarProperties = {
	mass: number,
	temperature: number,
	spectralClass: SpectralClass,
	luminosity: number,
	radius: number,
	age: number,
	lifespan: number,
}

local FirstStarStellarModel = {}

local function determineSpectralClass(temperature: number): SpectralClass
	if temperature >= 30000 then return "O" end
	if temperature >= 10000 then return "B" end
	if temperature >= 7500 then return "A" end
	if temperature >= 6000 then return "F" end
	if temperature >= 5200 then return "G" end
	if temperature >= 3700 then return "K" end
	return "M"
end

function FirstStarStellarModel.generate(rng: Rng): StellarProperties
	-- Mass in solar masses (M_sun). We favor 0.5 to 2.0 for standard stars.
	local mass = rng:nextRange(0.5, 2.0)
	
	-- Simplified main-sequence relations
	-- Luminosity (L_sun) ~ M^3.5
	local luminosity = math.pow(mass, 3.5)
	
	-- Radius (R_sun) ~ M^0.8
	local radius = math.pow(mass, 0.8)
	
	-- Temperature (K) ~ (L / R^2)^0.25 * 5778
	local temperature = math.pow(luminosity / (radius * radius), 0.25) * 5778
	
	local spectralClass = determineSpectralClass(temperature)
	
	-- Lifespan (years) ~ 1e10 * (M / L)
	local lifespan = 10000000000 * (mass / luminosity)
	
	-- Age (years). Let's make it somewhere between 1% and 50% of its lifespan.
	local ageFraction = rng:nextRange(0.01, 0.5)
	local age = lifespan * ageFraction
	
	return {
		mass = mass,
		temperature = temperature,
		spectralClass = spectralClass,
		luminosity = luminosity,
		radius = radius,
		age = age,
		lifespan = lifespan,
	}
end

return table.freeze(FirstStarStellarModel)
