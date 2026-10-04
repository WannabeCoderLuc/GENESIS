--!strict
local Result = require(script.Parent.Parent.Core.Result)
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Ids = require(script.Parent.Parent.Domain.Ids)

type Result<T> = Result.Result<T>

export type PathElement = { namespace: string, stableId: string }
export type UniverseAddressV1 = {
	elements: { PathElement }
}

local UniverseAddressV1 = {}

local MAX_ELEMENTS = 7

function UniverseAddressV1.validate(raw: any): Result<UniverseAddressV1>
	if type(raw) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "UniverseAddressV1 must be a table")
	end
	local elements = raw.elements
	if type(elements) ~= "table" then
		return Result.err(ErrorCodes.SCHEMA_INVALID, "elements must be a table")
	end
	local count = 0
	for k in pairs(elements) do
		if type(k) ~= "number" then
			return Result.err(ErrorCodes.SCHEMA_INVALID, "elements must be an array")
		end
		count += 1
	end
	if count > MAX_ELEMENTS then
		return Result.err(ErrorCodes.SCHEMA_LIMIT_EXCEEDED, "address too deep")
	end
	
	local outElements = table.create(count)
	for i = 1, count do
		local el = elements[i]
		if type(el) ~= "table" then
			return Result.err(ErrorCodes.SCHEMA_INVALID, "element must be a table")
		end
		if type(el.namespace) ~= "string" or not Ids.isStableIdText(el.namespace) then
			return Result.err(ErrorCodes.SCHEMA_INVALID, "invalid namespace")
		end
		if type(el.stableId) ~= "string" or not Ids.isStableIdText(el.stableId) then
			return Result.err(ErrorCodes.SCHEMA_INVALID, "invalid stableId")
		end
		outElements[i] = { namespace = el.namespace, stableId = el.stableId }
	end
	return Result.ok({ elements = outElements })
end

function UniverseAddressV1.format(address: UniverseAddressV1): string
	local parts = table.create(#address.elements)
	for i, el in ipairs(address.elements) do
		parts[i] = el.namespace .. ":" .. el.stableId
	end
	return table.concat(parts, "/")
end

function UniverseAddressV1.parse(text: string): Result<UniverseAddressV1>
	if #text > 1024 then
		return Result.err(ErrorCodes.SCHEMA_LIMIT_EXCEEDED, "address text too long")
	end
	local elements = {}
	if text == "" then
		return Result.ok({ elements = elements })
	end
	local parts = string.split(text, "/")
	if #parts > MAX_ELEMENTS then
		return Result.err(ErrorCodes.SCHEMA_LIMIT_EXCEEDED, "address too deep")
	end
	for i, part in ipairs(parts) do
		local ns, id = string.match(part, "^([^:]+):([^:]+)$")
		if not ns or not id then
			return Result.err(ErrorCodes.ADDRESS_INVALID, "malformed address segment")
		end
		if not Ids.isStableIdText(ns) or not Ids.isStableIdText(id) then
			return Result.err(ErrorCodes.ADDRESS_INVALID, "invalid stable ids in segment")
		end
		elements[i] = { namespace = ns, stableId = id }
	end
	return Result.ok({ elements = elements })
end

return UniverseAddressV1
