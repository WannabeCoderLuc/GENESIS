--!strict
local Result = require(game:GetService("ReplicatedStorage").Shared.Core.Result)
local ErrorCodes = require(game:GetService("ReplicatedStorage").Shared.Core.ErrorCodes)
local Lifecycle = require(game:GetService("ServerScriptService").Server.Application.Lifecycle)

return function(t: any)
	t.test("initialize, start and stop successfully", function()
		local lifecycle = Lifecycle.new()
		local events = {}
		
		lifecycle:register({
			name = "ServiceA",
			init = function()
				table.insert(events, "initA")
				return Result.ok(true)
			end,
			start = function()
				table.insert(events, "startA")
				return Result.ok(true)
			end,
			stop = function()
				table.insert(events, "stopA")
				return Result.ok(true)
			end,
		})
		
		lifecycle:register({
			name = "ServiceB",
			init = function()
				table.insert(events, "initB")
				return Result.ok(true)
			end,
			start = function()
				table.insert(events, "startB")
				return Result.ok(true)
			end,
			stop = function()
				table.insert(events, "stopB")
				return Result.ok(true)
			end,
		})
		
		local initRes = lifecycle:initAll()
		t.expect.equal(initRes.ok, true)
		t.expect.deepEqual(events, { "initA", "initB" })
		
		local startRes = lifecycle:startAll()
		t.expect.equal(startRes.ok, true)
		t.expect.deepEqual(events, { "initA", "initB", "startA", "startB" })
		
		local stopRes = lifecycle:stopAll()
		t.expect.equal(stopRes.ok, true)
		t.expect.deepEqual(events, { "initA", "initB", "startA", "startB", "stopB", "stopA" })
	end)

	t.test("stops in reverse order", function()
		local lifecycle = Lifecycle.new()
		local order = {}
		
		lifecycle:register({
			name = "S1",
			stop = function()
				table.insert(order, "S1")
				return Result.ok(true)
			end,
		})
		lifecycle:register({
			name = "S2",
			stop = function()
				table.insert(order, "S2")
				return Result.ok(true)
			end,
		})
		
		lifecycle:initAll()
		lifecycle:startAll()
		lifecycle:stopAll()
		
		t.expect.deepEqual(order, { "S2", "S1" })
	end)

	t.test("fails to start before init", function()
		local lifecycle = Lifecycle.new()
		local startRes = lifecycle:startAll()
		t.expect.equal(startRes.ok, false)
		t.expect.equal(startRes.code, ErrorCodes.INTERNAL_ERROR)
	end)

	t.test("handles service returning error", function()
		local lifecycle = Lifecycle.new()
		lifecycle:register({
			name = "BadService",
			init = function() return Result.err(ErrorCodes.INTERNAL_ERROR, "failed to init") end,
		})
		local initRes = lifecycle:initAll()
		t.expect.equal(initRes.ok, false)
		t.expect.equal(initRes.message, "failed to init")
	end)

	t.test("handles service raising exception", function()
		local lifecycle = Lifecycle.new()
		lifecycle:register({
			name = "ThrowingService",
			init = function() error("unexpected throw") end,
		})
		local initRes = lifecycle:initAll()
		t.expect.equal(initRes.ok, false)
		t.expect.equal(initRes.code, ErrorCodes.INTERNAL_ERROR)
	end)
end
