--!optimize 2
--!native

local Bindable = require("@game/ReplicatedStorage/Packages/Horus/_Index/Bindable")
local Sera = require("@game/ReplicatedStorage/Packages/Horus/_Index/Sera")
local SessionManager = require("@game/ReplicatedStorage/Packages/Horus/SessionManager")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage.Packages.Horus:FindFirstChild("Remotes")

local RemoteFunctionsServer = {}
RemoteFunctionsServer.__index = RemoteFunctionsServer

function RemoteFunctionsServer.new(remoteName: string, serviceName: string, requestSchema: any, responseSchema: any)
	local self = setmetatable({}, RemoteFunctionsServer)

	local serviceFolder = remotesFolder:FindFirstChild(serviceName)
	if not serviceFolder then
		serviceFolder = Instance.new("Folder")
		serviceFolder.Name = serviceName
		serviceFolder.Parent = remotesFolder
	end

	local requestRemote = serviceFolder:FindFirstChild(remoteName .. "Request")
	if not requestRemote then
		requestRemote = Instance.new("RemoteEvent")
		requestRemote.Name = remoteName .. "Request"
		requestRemote.Parent = serviceFolder
	end

	local responseRemote = serviceFolder:FindFirstChild(remoteName .. "Response")
	if not responseRemote then
		responseRemote = Instance.new("RemoteEvent")
		responseRemote.Name = remoteName .. "Response"
		responseRemote.Parent = serviceFolder
	end

	self._requestRemote = requestRemote :: RemoteEvent
	self._responseRemote = responseRemote :: RemoteEvent
	self._requestSchema = requestSchema
	self._responseSchema = responseSchema
	self._remoteName = remoteName
	self._signal = Bindable.new()
	self._isSignalConnected = false

	if requestSchema then
		requestRemote:SetAttribute("Schema", Sera.EncodeSchema(requestSchema))
	end
	if responseSchema then
		responseRemote:SetAttribute("Schema", Sera.EncodeSchema(responseSchema))
	end

	self._rateLimits = setmetatable({}, { __mode = "k" }) :: { [Player]: { count: number, lastReset: number } }

	self._requestRemote.OnServerEvent:Connect(function(player: Player, clientSeqId: any, ciphertext: any, tag: any)
		if not self._isSignalConnected then
			warn(`[Horus] {player.Name} tried to invoke '{self._remoteName}' before it was connected!`)
			return
		end

		if typeof(clientSeqId) ~= "number" or typeof(ciphertext) ~= "buffer" or typeof(tag) ~= "buffer" then
			warn(`[Horus] Malformed invoke from {player.Name} on '{self._remoteName}'`)
			return
		end

		local limit = self._rateLimits[player]
		local now = os.clock()
		if not limit or now - limit.lastReset > 1 then
			self._rateLimits[player] = { count = 1, lastReset = now }
		else
			limit.count += 1
			if limit.count > 20 then
				warn(`[Horus] Rate limit exceeded for {player.Name} on invoke '{self._remoteName}'`)
				return
			end
		end

		local session = SessionManager:GetSession(player)
		if not session then
			warn(`[Horus] No session for {player.Name}, rejecting invoke on '{self._remoteName}'`)
			return
		end

		local decryptOk, plaintext = SessionManager:Decrypt(session, clientSeqId, ciphertext, tag)
		if not decryptOk or not plaintext then
			warn(`[Horus] Request decryption/auth failed from {player.Name} on '{self._remoteName}' (seqId={clientSeqId})`)
			return
		end

		local deserOk, requestData = pcall(function()
			return Sera.Deserialize(self._requestSchema, plaintext :: buffer)
		end)
		if not deserOk then
			warn(`[Horus] Request deserialization failed from {player.Name} on '{self._remoteName}': {requestData}`)
			return
		end

		local handlerResult
		if self._requestSchema.IsArray then
			handlerResult = table.pack(pcall(self._invokeCallback, player, table.unpack(requestData)))
		else
			handlerResult = table.pack(pcall(self._invokeCallback, player, requestData))
		end

		local handlerOk = table.remove(handlerResult, 1)
		if not handlerOk then
			warn(`[Horus] Handler error on '{self._remoteName}': {handlerResult[1]}`)
			return
		end

		local responseData = if self._responseSchema.IsArray then handlerResult else handlerResult[1]

		local serializedResponse, serErr = Sera.Serialize(self._responseSchema, responseData)
		if not serializedResponse then
			warn(`[Horus] Response serialization failed on '{self._remoteName}': {serErr}`)
			return
		end

		local respSeqId, respCiphertext, respTag = SessionManager:Encrypt(session, serializedResponse)
		self._responseRemote:FireClient(player, clientSeqId, respSeqId, respCiphertext, respTag)
	end)

	return self
end

function RemoteFunctionsServer:OnInvoke(callback: (Player, ...any) -> ...any)
	if self._isSignalConnected then
		warn(`[Horus] OnInvoke already connected on '{self._remoteName}'`)
		return nil
	end

	self._invokeCallback = callback
	self._isSignalConnected = true

	local connection = self._signal:Connect(callback)
	local originalDisconnect = connection.Disconnect

	connection.Disconnect = function(conn)
		self._invokeCallback = nil
		self._isSignalConnected = false
		originalDisconnect(conn)
	end

	return connection
end

return RemoteFunctionsServer

