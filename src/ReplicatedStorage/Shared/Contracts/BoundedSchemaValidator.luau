--!strict
local ErrorCodes = require(script.Parent.Parent.Core.ErrorCodes)
local Result = require(script.Parent.Parent.Core.Result)

type Result<T> = Result.Result<T>

local BoundedSchemaValidator = {}

export type BoundedLimits = {
	maxDepth: number,
	maxNodes: number,
	maxStringBytes: number,
}

function BoundedSchemaValidator.checkLimits(val: any, limits: BoundedLimits): Result<nil>
	local state = { count = 0 }
	local visited = {}
	
	local function traverse(node: any, depth: number): boolean
		state.count += 1
		if state.count > limits.maxNodes then return false end
		if depth > limits.maxDepth then return false end
		
		local t = type(node)
		if t == "function" or t == "userdata" or t == "thread" then return false end
		
		if t == "table" then
			if visited[node] then return false end
			visited[node] = true
			
			for k, v in pairs(node) do
				local tk = type(k)
				if tk ~= "string" and tk ~= "number" then return false end
				if tk == "string" and #k > limits.maxStringBytes then return false end
				
				local tv = type(v)
				if tv == "string" and #v > limits.maxStringBytes then return false end
				if not traverse(v, depth + 1) then return false end
			end
		end
		return true
	end
	
	if traverse(val, 1) then
		return Result.ok(nil)
	end
	return Result.err(ErrorCodes.SCHEMA_LIMIT_EXCEEDED, "payload exceeds size or depth limits")
end

return BoundedSchemaValidator
