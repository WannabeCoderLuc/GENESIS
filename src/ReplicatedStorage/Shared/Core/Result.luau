--!strict
--[[
	Result: typed success/failure values for EXPECTED failures (bad input, store errors, rejected commands).
	Exceptions are reserved for programmer errors. Never ignore a pcall failure: convert it with Result.protect.

	Authority: shared, pure. Error codes are stable strings from ErrorCodes.
]]

export type ErrorContext = { [string]: string | number | boolean }
export type Ok<T> = { ok: true, value: T }
export type Err = { ok: false, code: string, message: string, context: ErrorContext? }
export type Result<T> = Ok<T> | Err

local Result = {}

function Result.ok<T>(value: T): Ok<T>
	return { ok = true, value = value }
end

function Result.err(code: string, message: string, context: ErrorContext?): Err
	return { ok = false, code = code, message = message, context = context }
end

-- Applies fn to a success value; failures pass through untouched.
function Result.map<T, U>(result: Result<T>, fn: (T) -> U): Result<U>
	if result.ok then
		return Result.ok(fn(result.value))
	end
	return result
end

-- Chains a fallible step; failures short-circuit.
function Result.andThen<T, U>(result: Result<T>, fn: (T) -> Result<U>): Result<U>
	if result.ok then
		return fn(result.value)
	end
	return result
end

function Result.unwrapOr<T>(result: Result<T>, fallback: T): T
	if result.ok then
		return result.value
	end
	return fallback
end

-- For tests and bootstrap only: raises on failure with the stable code in the message.
function Result.unwrap<T>(result: Result<T>): T
	if result.ok then
		return result.value
	end
	error(string.format("Result.unwrap on Err %s: %s", result.code, result.message), 2)
end

-- Runs fn under pcall and converts a raised error into a typed boundary failure.
function Result.protect(code: string, label: string, fn: (...any) -> any, ...: any): Result<any>
	local ok, value = pcall(fn, ...)
	if ok then
		return Result.ok(value)
	end
	return Result.err(code, label .. " raised an error", { detail = tostring(value) })
end

return Result
