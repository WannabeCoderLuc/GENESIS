--!strict
--[[
	TestContext: the type handed to every spec function. A spec module returns `function(t: TestContext) ... end`
	and registers cases with t.test(name, fn); each case runs immediately and in isolation.
]]

export type TestContext = {
	test: (name: string, fn: () -> ()) -> (),
	expect: typeof(require(script.Parent.Expect)),
}

return {}
