--!optimize 2
--!native

local Sera = require("../_Index/Sera")
local SessionManager =  require("../SessionManager")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage.Packages.Horus:FindFirstChild("Remotes")

local RemoteEventsClient = {}
RemoteEventsClient.__index = RemoteEventsClient

function RemoteEventsClient.new(remoteName: string, serviceName: string)
	local self = setmetatable({}, RemoteEventsClient)

	local serviceFolder = remotesFolder:WaitForChild(serviceName, 30)
	local remote = serviceFolder:WaitForChild(remoteName, 30)

	if not remote or not remote:IsA("RemoteEvent") then
		warn(`[Horus] RemoteEvent '{remoteName}' not found in Remotes/{serviceName}`)
	end

	local schemaStr = remote:GetAttribute("Schema")
	if not schemaStr then
		remote:GetAttributeChangedSignal("Schema"):Wait()
		schemaStr = remote:GetAttribute("Schema")
	end

	self._remote = remote :: RemoteEvent
	self._schema = Sera.DecodeSchema(schemaStr)
	self._remoteName = remoteName

	return self
end

function RemoteEventsClient:Fire(...: any)
	local session = SessionManager:WaitForSession()

	local data = if self._schema.IsArray then {...} else (...)
	local serialized, serErr = Sera.Serialize(self._schema, data)
	if not serialized then
		warn(`[Horus] Serialization failed on '{self._remoteName}': {serErr}`)
		return
	end

	local seqId, ciphertext, tag = SessionManager:Encrypt(session, serialized)
	self._remote:FireServer(seqId, ciphertext, tag)
end

function RemoteEventsClient:OnEvent(callback: (...any) -> ())
	self._remote.OnClientEvent:Connect(function(seqId: any, ciphertext: any, tag: any)
		if typeof(seqId) ~= "number" or typeof(ciphertext) ~= "buffer" or typeof(tag) ~= "buffer" then
			warn(`[Horus] Malformed packet from server on '{self._remoteName}'`)
			return
		end

		local session = SessionManager:WaitForSession()
		if not session then
			warn(`[Horus] No session established, dropping event on '{self._remoteName}'`)
			return
		end

		local success, plaintext = SessionManager:Decrypt(session, seqId, ciphertext, tag)
		if not success or not plaintext then
			warn(`[Horus] Decryption/auth failed from server on '{self._remoteName}' (seqId={seqId})`)
			return
		end

		local ok, deserialized = pcall(function()
			return Sera.Deserialize(self._schema, plaintext :: buffer)
		end)
		if not ok then
			warn(`[Horus] Deserialization failed from server on '{self._remoteName}': {deserialized}`)
			return
		end

		if self._schema.IsArray then
			callback(table.unpack(deserialized))
		else
			callback(deserialized)
		end
	end)
end

return RemoteEventsClient
