--!optimize 2
--!native

local Sera = require("../_Index/Sera")
local SessionManager = require("../SessionManager")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage.Packages.Horus:FindFirstChild("Remotes")

local RemoteFunctionsClient = {}
RemoteFunctionsClient.__index = RemoteFunctionsClient

function RemoteFunctionsClient.new(remoteName: string, serviceName: string, requestSchema: any, responseSchema: any)
	local self = setmetatable({}, RemoteFunctionsClient)

	local serviceFolder = remotesFolder:WaitForChild(serviceName, 30)

	local requestRemote = serviceFolder:WaitForChild(remoteName .. "Request", 30)
	if not requestRemote or not requestRemote:IsA("RemoteEvent") then
		warn(`[Horus] RemoteEvent '{remoteName}Request' not found in Remotes/{serviceName}`)
	end

	local responseRemote = serviceFolder:WaitForChild(remoteName .. "Response", 30)
	if not responseRemote or not responseRemote:IsA("RemoteEvent") then
		warn(`[Horus] RemoteEvent '{remoteName}Response' not found in Remotes/{serviceName}`)
	end

	if requestSchema or responseSchema then
		warn(`[Horus] Client should not set schemas for '{remoteName}'. Waiting for Server's schemas...`)
	end

	local reqSchemaStr = requestRemote:GetAttribute("Schema")
	if not reqSchemaStr then
		requestRemote:GetAttributeChangedSignal("Schema"):Wait()
		reqSchemaStr = requestRemote:GetAttribute("Schema")
	end

	local resSchemaStr = responseRemote:GetAttribute("Schema")
	if not resSchemaStr then
		responseRemote:GetAttributeChangedSignal("Schema"):Wait()
		resSchemaStr = responseRemote:GetAttribute("Schema")
	end

	self._requestRemote = requestRemote :: RemoteEvent
	self._responseRemote = responseRemote :: RemoteEvent
	self._requestSchema = Sera.DecodeSchema(reqSchemaStr)
	self._responseSchema = Sera.DecodeSchema(resSchemaStr)
	self._remoteName = remoteName
	self._threads = {} :: { [number]: { thread: thread, timeout: thread } }

	self._responseRemote.OnClientEvent:Connect(function(clientSeqId: any, respSeqId: any, respCiphertext: any, respTag: any)
		local entry = self._threads[clientSeqId]
		if not entry then
			warn(`[Horus] Received response for unknown seqId {clientSeqId} on '{self._remoteName}' (timed out or duplicate)`)
			return
		end

		task.cancel(entry.timeout)
		self._threads[clientSeqId] = nil
		coroutine.resume(entry.thread, respSeqId, respCiphertext, respTag)
	end)

	return self
end

function RemoteFunctionsClient:Invoke(...: any): any
	local session = SessionManager:WaitForSession()

	local data = if self._requestSchema.IsArray then {...} else (...)
	local serialized, serErr = Sera.Serialize(self._requestSchema, data)
	if not serialized then
		warn(`[Horus] Request serialization failed on '{self._remoteName}': {serErr}`)
		return nil
	end

	local seqId, ciphertext, tag = SessionManager:Encrypt(session, serialized)

	local callingThread = coroutine.running()
	local timeoutTask = task.delay(10, function()
		local entry = self._threads[seqId]
		if entry then
			self._threads[seqId] = nil
			coroutine.resume(entry.thread)
		end
	end)

	self._threads[seqId] = { thread = callingThread, timeout = timeoutTask }
	self._requestRemote:FireServer(seqId, ciphertext, tag)

	local respSeqId, respCiphertext, respTag = coroutine.yield()

	if respSeqId == nil or typeof(respSeqId) ~= "number" then
		warn(`[Horus] Server returned nil/invalid response for '{self._remoteName}' (timed out or error)`)
		return nil
	end

	if typeof(respCiphertext) ~= "buffer" or typeof(respTag) ~= "buffer" then
		warn(`[Horus] Malformed response from server on '{self._remoteName}'`)
		return nil
	end

	local success, plaintext = SessionManager:Decrypt(session, respSeqId, respCiphertext, respTag)
	if not success or not plaintext then
		warn(`[Horus] Response decryption/auth failed on '{self._remoteName}' (seqId={respSeqId})`)
		return nil
	end

	local ok, deserialized = pcall(function()
		return Sera.Deserialize(self._responseSchema, plaintext :: buffer)
	end)
	if not ok then
		warn(`[Horus] Response deserialization failed on '{self._remoteName}': {deserialized}`)
		return nil
	end

	if self._responseSchema.IsArray then
		return table.unpack(deserialized)
	else
		return deserialized
	end
end

return RemoteFunctionsClient
