--!strict
--[[
	Expect: assertion helpers for specs. Every failure raises with a message naming expected vs actual.
	Matchers return useful values (isOk returns the unwrapped value) so specs stay linear.
]]

local Result = require(game:GetService("ReplicatedStorage").Shared.Core.Result)

type Result<T> = Result.Result<T>

local Expect = {}

local function describe(value: any, depth: number?): string
	local level = depth or 0
	local kind = type(value)
	if kind == "string" then
		if #value > 80 then
			return string.format("%q...(%d bytes)", string.sub(value, 1, 80), #value)
		end
		return string.format("%q", value)
	elseif kind == "table" then
		if level >= 2 then
			return "{...}"
		end
		local parts = {}
		local count = 0
		for key, item in pairs(value) do
			count += 1
			if count > 6 then
				parts[#parts + 1] = "..."
				break
			end
			parts[#parts + 1] = tostring(key) .. "=" .. describe(item, level + 1)
		end
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value)
end

local function deepEquals(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) == "number" and type(b) == "number" and a ~= a and b ~= b then
		return true -- NaN equals NaN for comparison purposes
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in pairs(a) do
		if not deepEquals(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

Expect.describe = describe
Expect.deepEquals = deepEquals

function Expect.equal(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(string.format("%sexpected %s, got %s", if label then label .. ": " else "", describe(expected), describe(actual)), 2)
	end
end

function Expect.notEqual(actual: any, unexpected: any, label: string?)
	if actual == unexpected then
		error(string.format("%sexpected a value different from %s", if label then label .. ": " else "", describe(unexpected)), 2)
	end
end

function Expect.deepEqual(actual: any, expected: any, label: string?)
	if not deepEquals(actual, expected) then
		error(string.format("%sexpected %s, got %s", if label then label .. ": " else "", describe(expected), describe(actual)), 2)
	end
end

function Expect.truthy(value: any, label: string?)
	if not value then
		error(string.format("%sexpected truthy, got %s", if label then label .. ": " else "", describe(value)), 2)
	end
end

function Expect.falsy(value: any, label: string?)
	if value then
		error(string.format("%sexpected falsy, got %s", if label then label .. ": " else "", describe(value)), 2)
	end
end

function Expect.near(actual: number, expected: number, tolerance: number, label: string?)
	if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
		error(string.format("%sexpected %s within %s of %s", if label then label .. ": " else "", describe(actual), describe(tolerance), describe(expected)), 2)
	end
end

function Expect.finite(value: any, label: string?)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		error(string.format("%sexpected a finite number, got %s", if label then label .. ": " else "", describe(value)), 2)
	end
end

-- Inclusive bounds.
function Expect.between(value: number, low: number, high: number, label: string?)
	Expect.finite(value, label)
	if value < low or value > high then
		error(string.format("%sexpected %s in [%s, %s]", if label then label .. ": " else "", describe(value), describe(low), describe(high)), 2)
	end
end

-- Raises if fn does NOT raise; returns the error message.
function Expect.throws(fn: () -> (), contains: string?): string
	local ok, err = pcall(fn)
	if ok then
		error("expected the function to raise, but it returned normally", 2)
	end
	local message = tostring(err)
	if contains ~= nil and not string.find(message, contains, 1, true) then
		error(string.format("expected error containing %q, got %q", contains, message), 2)
	end
	return message
end

-- Fails the test if the Result is an Err; otherwise returns the value.
function Expect.isOk<T>(result: Result<T>, label: string?): T
	if not result.ok then
		error(string.format("%sexpected Ok, got Err %s: %s", if label then label .. ": " else "", result.code, result.message), 2)
	end
	return result.value
end

-- Fails the test unless the Result is an Err (optionally with the given stable code).
function Expect.isErr(result: Result<any>, code: string?, label: string?)
	if result.ok then
		error(string.format("%sexpected Err%s, got Ok", if label then label .. ": " else "", if code then " " .. code else ""), 2)
	end
	if code ~= nil and result.code ~= code then
		error(string.format("%sexpected Err %s, got %s: %s", if label then label .. ": " else "", code, result.code, result.message), 2)
	end
end

return Expect
