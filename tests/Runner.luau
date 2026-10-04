--!strict
--[[
	Runner: discovers "*.spec" ModuleScripts under the Tests container (or any root) and runs their cases.

	Spec contract (same shape as Roblox's built-in rbx-unit-test harness so either runner can execute it):
	    return function(t) t.test("behaviour", function() ... end) end

	Run from Studio MCP (Edit or Play, server context):
	    require(game.ServerStorage.Tests.Runner).run({ filter = "Seed" })

	The returned Report is plain JSON-serialisable data: counts, per-suite results and every failure with its message.
	A case "fails" if it raises, or "times out" if it is still suspended after timeoutSec. Suites run in sorted order
	so reports are comparable between runs.
]]

local Expect = require(script.Parent.Support.Expect)

export type Failure = { suite: string, name: string, status: string, message: string }
export type SuiteReport = { suite: string, passed: number, failed: number }
export type Report = {
	total: number,
	passed: number,
	failed: number,
	durationSec: number,
	filter: string?,
	suites: { SuiteReport },
	failures: { Failure },
}
export type Options = { root: Instance?, filter: string?, timeoutSec: number?, verbose: boolean? }

local Runner = {}

local DEFAULT_TIMEOUT_SEC = 20
local SPEC_SUFFIX = ".spec"

local function relativeName(module: ModuleScript, root: Instance): string
	local parts = { module.Name }
	local current = module.Parent
	while current ~= nil and current ~= root do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end
	local joined = table.concat(parts, "/")
	return string.sub(joined, 1, #joined - #SPEC_SUFFIX)
end

local function collectSpecs(root: Instance): { ModuleScript }
	local specs = {}
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("ModuleScript") and string.sub(descendant.Name, -#SPEC_SUFFIX) == SPEC_SUFFIX then
			table.insert(specs, descendant)
		end
	end
	table.sort(specs, function(a, b)
		return relativeName(a, root) < relativeName(b, root)
	end)
	return specs
end

-- Runs fn; returns (status, message). status is "pass" | "fail" | "timeout".
local function runCase(fn: () -> (), timeoutSec: number): (string, string)
	local finished = false
	local ok = false
	local message = ""
	task.spawn(function()
		local success, err = xpcall(fn, function(raised)
			return tostring(raised) .. "\n" .. debug.traceback()
		end)
		ok = success
		if not success then
			message = tostring(err)
		end
		finished = true
	end)
	local waited = 0
	while not finished and waited < timeoutSec do
		waited += task.wait(0.05)
	end
	if not finished then
		return "timeout", string.format("still running after %.1fs", timeoutSec)
	end
	return if ok then "pass" else "fail", message
end

function Runner.run(options: Options?): Report
	local opts: Options = options or {}
	local root: Instance = opts.root or script.Parent :: Instance
	local timeoutSec = opts.timeoutSec or DEFAULT_TIMEOUT_SEC
	local started = os.clock()

	local report: Report = {
		total = 0,
		passed = 0,
		failed = 0,
		durationSec = 0,
		filter = opts.filter,
		suites = {},
		failures = {},
	}

	for _, module in ipairs(collectSpecs(root)) do
		local suite = relativeName(module, root)
		if opts.filter == nil or string.find(suite, opts.filter, 1, true) then
			local suiteReport: SuiteReport = { suite = suite, passed = 0, failed = 0 }
			local context = {
				expect = Expect,
				test = function(name: string, fn: () -> ())
					report.total += 1
					local status, message = runCase(fn, timeoutSec)
					if status == "pass" then
						report.passed += 1
						suiteReport.passed += 1
					else
						report.failed += 1
						suiteReport.failed += 1
						table.insert(report.failures, { suite = suite, name = name, status = status, message = message })
					end
				end,
			}
			local loaded, specFn = pcall(require, module)
			if not loaded or type(specFn) ~= "function" then
				report.total += 1
				report.failed += 1
				suiteReport.failed += 1
				table.insert(report.failures, {
					suite = suite,
					name = "<load>",
					status = "fail",
					message = if loaded then "spec module did not return a function" else tostring(specFn),
				})
			else
				local built, buildErr = xpcall(specFn, function(raised)
					return tostring(raised) .. "\n" .. debug.traceback()
				end, context)
				if not built then
					report.total += 1
					report.failed += 1
					suiteReport.failed += 1
					table.insert(report.failures, { suite = suite, name = "<build>", status = "fail", message = tostring(buildErr) })
				end
			end
			table.insert(report.suites, suiteReport)
		end
	end

	report.durationSec = os.clock() - started
	return report
end

return Runner
