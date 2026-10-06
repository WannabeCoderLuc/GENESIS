--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Result = require(ReplicatedStorage.Shared.Core.Result)
local ErrorCodes = require(ReplicatedStorage.Shared.Core.ErrorCodes)
local FirstStarStellarModel = require(ReplicatedStorage.Shared.Domain.FirstStarStellarModel)
local FirstStarStateV1 = require(ReplicatedStorage.Shared.Contracts.FirstStarStateV1)
local FirstStarCommandV1 = require(ReplicatedStorage.Shared.Contracts.FirstStarCommandV1)
local Seed = require(ReplicatedStorage.Shared.Domain.Seed)
local Rng = require(ReplicatedStorage.Shared.Domain.Rng)
local Versions = require(ReplicatedStorage.Shared.Domain.Versions)

type Result<T> = Result.Result<T>
type Seed = Seed.Seed
type FirstStarStateV1 = FirstStarStateV1.FirstStarStateV1
type IgnitionCommandV1 = FirstStarCommandV1.IgnitionCommandV1

export type FirstStarAggregate = typeof(setmetatable({} :: {
	state: FirstStarStateV1?
}, {} :: any))

local FirstStarAggregate = {}
FirstStarAggregate.__index = FirstStarAggregate

function FirstStarAggregate.new(state: FirstStarStateV1?): FirstStarAggregate
	local self = setmetatable({
		state = state,
	}, FirstStarAggregate)
	return self
end

function FirstStarAggregate:handleIgnition(command: IgnitionCommandV1, universeSeed: Seed, now: number): Result<FirstStarStateV1>
	if self.state ~= nil then
		return Result.err(ErrorCodes.FIRST_STAR_ALREADY_IGNITED, "First star is already ignited for this universe")
	end
	
	local generatorVersionResult = Versions.generatorVersion(1)
	if not generatorVersionResult.ok then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Invalid generator version")
	end
	
	local starSeedResult = Seed.derive(universeSeed, "first_star", "1", generatorVersionResult.value)
	if not starSeedResult.ok then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Failed to derive first star seed: " .. tostring(starSeedResult.message))
	end
	
	local rng = Rng.new(starSeedResult.value)
	local properties = FirstStarStellarModel.generate(rng)
	
	local newState = {
		schemaVersion = 1,
		mass = properties.mass,
		temperature = properties.temperature,
		spectralClass = properties.spectralClass,
		luminosity = properties.luminosity,
		radius = properties.radius,
		age = properties.age,
		lifespan = properties.lifespan,
		ignitedAt = now,
	}
	
	local validationResult = FirstStarStateV1.validate(newState)
	if not validationResult.ok then
		return Result.err(ErrorCodes.INTERNAL_ERROR, "Generated first star state is invalid: " .. validationResult.message)
	end
	
	self.state = validationResult.value
	
	return Result.ok(self.state :: FirstStarStateV1)
end

return FirstStarAggregate
