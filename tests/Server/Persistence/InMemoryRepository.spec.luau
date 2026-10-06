--!strict
local InMemoryRepository = require(game:GetService("ServerScriptService").Server.Persistence.InMemoryRepository)

return function(t: any)
	t.test("set and get values", function()
		local repo = InMemoryRepository.new()
		local get1 = repo:get("key1")
		t.expect.equal(get1.ok, true)
		t.expect.equal(get1.value, nil)

		local set1 = repo:set("key1", { data = 123 })
		t.expect.equal(set1.ok, true)

		local get2 = repo:get("key1")
		t.expect.equal(get2.ok, true)
		t.expect.equal(get2.value.data, 123)
	end)

	t.test("update values", function()
		local repo = InMemoryRepository.new()
		repo:set("counter", 1)
		local updated = repo:update("counter", function(val)
			return (val or 0) + 1
		end)
		t.expect.equal(updated.ok, true)
		t.expect.equal(updated.value, 2)

		local get1 = repo:get("counter")
		t.expect.equal(get1.value, 2)
	end)

	t.test("delete values", function()
		local repo = InMemoryRepository.new()
		repo:set("key1", "value1")
		local del1 = repo:delete("key1")
		t.expect.equal(del1.ok, true)
		t.expect.equal(del1.value, true)

		local get1 = repo:get("key1")
		t.expect.equal(get1.value, nil)

		local del2 = repo:delete("key1")
		t.expect.equal(del2.ok, true)
		t.expect.equal(del2.value, false)
	end)
end
