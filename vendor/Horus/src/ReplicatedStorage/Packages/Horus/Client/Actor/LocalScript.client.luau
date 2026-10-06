--!strict
--@author: crusherfire
--@date: 5/8/24
--[[@description:
	General code for loading parallel module scripts.
]]
-----------------------------
-- DEPENDENCIES --
-----------------------------
-- The loader clones the ParallelModuleLoader into this actor as a sibling of this LocalScript,
-- so we resolve it relatively rather than hardcoding a path under ReplicatedStorage.
local ParallelModuleLoader = require(script.Parent:WaitForChild("ParallelModuleLoader"))

-----------------------------
-- VARIABLES --
-----------------------------
local actor = script.Parent

-----------------------------
-- HANDLERS --
-----------------------------
actor:BindToMessage("RequireModule", function(module: ModuleScript)
	ParallelModuleLoader.onRequireModule(script, module)
end)

actor:BindToMessage("InitModule", function()
	ParallelModuleLoader.onInitModule(script)
end)

actor:BindToMessage("StartModule", function()
	ParallelModuleLoader.onStartModule(script)
end)

-----------------------------
-- MAIN --
-----------------------------
script:SetAttribute("Loaded", true)