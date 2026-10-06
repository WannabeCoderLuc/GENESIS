--!strict
local Result = require(game:GetService("ReplicatedStorage").Shared.Core.Result)
local ErrorCodes = require(game:GetService("ReplicatedStorage").Shared.Core.ErrorCodes)
local MigrationHarness = require(game:GetService("ServerScriptService").Server.Persistence.MigrationHarness)

return function(t: any)
	t.test("migrate to target version", function()
		local harness = MigrationHarness.new()
		harness:register({
			fromVersion = 0,
			toVersion = 1,
			migrate = function(raw: any)
				raw.name = raw.oldName or "Unknown"
				raw.oldName = nil
				return Result.ok(raw)
			end,
		})

		harness:register({
			fromVersion = 1,
			toVersion = 2,
			migrate = function(raw: any)
				raw.score = 0
				return Result.ok(raw)
			end,
		})

		local data = { oldName = "Player1" }
		local migrated = harness:migrate(data, 2)
		t.expect.equal(migrated.ok, true)
		t.expect.equal(migrated.value.schemaVersion, 2)
		t.expect.equal(migrated.value.name, "Player1")
		t.expect.equal(migrated.value.oldName, nil)
		t.expect.equal(migrated.value.score, 0)
	end)

	t.test("fails if no migration found", function()
		local harness = MigrationHarness.new()
		local data = { schemaVersion = 1 }
		local migrated = harness:migrate(data, 2)
		t.expect.equal(migrated.ok, false)
		t.expect.equal(migrated.code, ErrorCodes.SCHEMA_INVALID)
	end)

	t.test("fails if migration returns error", function()
		local harness = MigrationHarness.new()
		harness:register({
			fromVersion = 0,
			toVersion = 1,
			migrate = function(_raw: any)
				return Result.err(ErrorCodes.SCHEMA_INVALID, "Migration failed")
			end,
		})

		local data = {}
		local migrated = harness:migrate(data, 1)
		t.expect.equal(migrated.ok, false)
		t.expect.equal(migrated.message, "Migration failed")
	end)
end
