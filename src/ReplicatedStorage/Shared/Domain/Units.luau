--!strict
--[[
	Units: branded physical/gameplay quantities stored as INTEGERS in an explicit base unit.

	Durable economy and canonical simulation values are integer/fixed-point so float drift cannot change
	outcomes (AGENTS.md hard rules). The unit is part of the type name and of the field naming convention
	(massMilliSolar, durationMs, ...). Floats exist only in the explicit *ToPresentation helpers, which are
	for display and must never feed back into canonical state.

	Checked arithmetic never silently wraps or clamps: it returns UNIT_OVERFLOW / UNIT_UNDERFLOW.

	Authority: shared, pure.
]]

local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Result = require(script.Parent.Parent.Core.Result)

type Result<T> = Result.Result<T>

export type MassMilliSolar = number & { __brand: "MassMilliSolar" } -- 1000 = one solar mass
export type TemperatureKelvin = number & { __brand: "TemperatureKelvin" }
export type DistanceMilliAu = number & { __brand: "DistanceMilliAu" } -- 1000 = one astronomical unit
export type DurationMs = number & { __brand: "DurationMs" }
export type TimestampMs = number & { __brand: "TimestampMs" } -- server-authoritative Unix epoch milliseconds
export type Permille = number & { __brand: "Permille" } -- 0..1000 (1000 = 100%)
export type ResourceMilli = number & { __brand: "ResourceMilli" } -- 1000 = one whole unit of a resource

local MAX_SAFE_INTEGER = 9007199254740991
local MAX_TEMPERATURE_KELVIN = 1000000000

local Units = {}

Units.MAX_SAFE_INTEGER = MAX_SAFE_INTEGER
Units.MAX_RESOURCE_MILLI = MAX_SAFE_INTEGER
Units.PERMILLE_FULL = 1000

local function parseIntegerInRange(raw: unknown, label: string, minimum: number, maximum: number): Result<number>
	if type(raw) ~= "number" or raw ~= raw then
		return Result.err(ErrorCodes.UNIT_INVALID, label .. " must be a finite number")
	end
	if raw < minimum or raw > maximum or raw ~= math.floor(raw) then
		return Result.err(ErrorCodes.UNIT_INVALID, label .. " must be an integer in range", { minimum = minimum, maximum = maximum })
	end
	return Result.ok(raw)
end

function Units.massMilliSolar(raw: unknown): Result<MassMilliSolar>
	return parseIntegerInRange(raw, "MassMilliSolar", 0, MAX_SAFE_INTEGER) :: any
end

function Units.temperatureKelvin(raw: unknown): Result<TemperatureKelvin>
	return parseIntegerInRange(raw, "TemperatureKelvin", 0, MAX_TEMPERATURE_KELVIN) :: any
end

function Units.distanceMilliAu(raw: unknown): Result<DistanceMilliAu>
	return parseIntegerInRange(raw, "DistanceMilliAu", 0, MAX_SAFE_INTEGER) :: any
end

function Units.durationMs(raw: unknown): Result<DurationMs>
	return parseIntegerInRange(raw, "DurationMs", 0, MAX_SAFE_INTEGER) :: any
end

function Units.timestampMs(raw: unknown): Result<TimestampMs>
	return parseIntegerInRange(raw, "TimestampMs", 0, MAX_SAFE_INTEGER) :: any
end

function Units.permille(raw: unknown): Result<Permille>
	return parseIntegerInRange(raw, "Permille", 0, 1000) :: any
end

function Units.resourceMilli(raw: unknown): Result<ResourceMilli>
	return parseIntegerInRange(raw, "ResourceMilli", 0, MAX_SAFE_INTEGER) :: any
end

-- Checked a + b. Fails with UNIT_OVERFLOW instead of exceeding MAX_RESOURCE_MILLI.
function Units.addResource(a: ResourceMilli, b: ResourceMilli): Result<ResourceMilli>
	local sum = (a :: number) + (b :: number)
	if sum > MAX_SAFE_INTEGER then
		return Result.err(ErrorCodes.UNIT_OVERFLOW, "resource addition exceeds the maximum")
	end
	return Result.ok(sum :: any)
end

-- Checked a - b. Fails with UNIT_UNDERFLOW instead of going negative.
function Units.subResource(a: ResourceMilli, b: ResourceMilli): Result<ResourceMilli>
	local difference = (a :: number) - (b :: number)
	if difference < 0 then
		return Result.err(ErrorCodes.UNIT_UNDERFLOW, "resource subtraction would go negative")
	end
	return Result.ok(difference :: any)
end

-- floor(value * ratio / 1000), computed without ever forming value * ratio (which could exceed 2^53).
-- value = 1000q + r  =>  floor(value * p / 1000) = q * p + floor(r * p / 1000).
function Units.scaleByPermille(value: ResourceMilli, ratio: Permille): ResourceMilli
	local amount = value :: number
	local p = ratio :: number
	local quotient = math.floor(amount / 1000)
	local remainder = amount - quotient * 1000
	return (quotient * p + math.floor(remainder * p / 1000)) :: any
end

-- Presentation only (floats). Never use the result as canonical state.
function Units.milliSolarToPresentationSolar(mass: MassMilliSolar): number
	return (mass :: number) / 1000
end

function Units.milliAuToPresentationAu(distance: DistanceMilliAu): number
	return (distance :: number) / 1000
end

function Units.durationToPresentationSeconds(duration: DurationMs): number
	return (duration :: number) / 1000
end

return Units
