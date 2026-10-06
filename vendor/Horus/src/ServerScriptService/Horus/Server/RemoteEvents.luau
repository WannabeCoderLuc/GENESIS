--!optimize 2
--!native

local Bindable = require("@game/ReplicatedStorage/Packages/Horus/_Index/Bindable")
local Sera = require("@game/ReplicatedStorage/Packages/Horus/_Index/Sera")
local SessionManager = require("@game/ReplicatedStorage/Packages/Horus/SessionManager")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotesFolder = ReplicatedStorage.Packages.Horus:FindFirstChild("Remotes")

local RemoteEventsServer = {}
RemoteEventsServer.__index = RemoteEventsServer

function RemoteEventsServer.new(remoteName: string, serviceName: string, schema: any)
	local self = setmetatable({}, RemoteEventsServer)

	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	local serviceFolder = remotesFolder:FindFirstChild(serviceName)
	if not serviceFolder then
		serviceFolder = Instance.new("Folder")
		serviceFolder.Name = serviceName
		serviceFolder.Parent = remotesFolder
	end

	local remote = serviceFolder:FindFirstChild(remoteName)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = serviceFolder
	end

	self._remote = remote :: RemoteEvent
	self._schema = schema
	self._remoteName = remoteName
	self._signal = Bindable.new()
	self._isSignalConnected = false

	if schema then
		remote:SetAttribute("Schema", Sera.EncodeSchema(schema))
	end

	self._rateLimits = setmetatable({}, { __mode = "k" }) :: { [Player]: { count: number, lastReset: number } }

	self._remote.OnServerEvent:Connect(function(player: Player, seqId: any, ciphertext: any, tag: any)
		if not self._isSignalConnected then
			warn(`[Horus] {player.Name} tried to fire '{self._remoteName}' before it was connected!`)
			return
		end

		if typeof(seqId) ~= "number" or typeof(ciphertext) ~= "buffer" or typeof(tag) ~= "buffer" then
			warn(`[Horus] Malformed packet from {player.Name} on '{self._remoteName}'`)
			return
		end

		local limit = self._rateLimits[player]
		local now = os.clock()
		if not limit or now - limit.lastReset > 1 then
			self._rateLimits[player] = { count = 1, lastReset = now }
		else
			limit.count += 1
			if limit.count > 60 then
				warn(`[Horus] Rate limit exceeded for {player.Name} on event '{self._remoteName}'`)
				return
			end
		end

		local session = SessionManager:GetSession(player)
		if not session then
			warn(`[Horus] No session for {player.Name}, dropping event on '{self._remoteName}'`)
			return
		end

		local success, plaintext = SessionManager:Decrypt(session, seqId, ciphertext, tag)
		if not success or not plaintext then
			warn(`[Horus] Decryption/auth failed from {player.Name} on '{self._remoteName}' (seqId={seqId})`)
			return
		end

		local ok, deserialized = pcall(function(): any
			return Sera.Deserialize(self._schema, plaintext :: buffer)
		end)

		if not ok then
			warn(`[Horus] Deserialization failed from {player.Name} on '{self._remoteName}': {deserialized}`)
			return
		end

		if self._schema.IsArray then
			self._signal:Fire(player, table.unpack(deserialized))
		else
			self._signal:Fire(player, deserialized)
		end
	end)

	return self
end

function RemoteEventsServer:Fire(player: Player, ...: any)
	local session = SessionManager:GetSession(player)
	if not session then
		warn(`[Horus] No session for player {player.Name}, cannot fire '{self._remoteName}'`)
		return
	end

	local data = if self._schema.IsArray then {...} else (...)
	local serialized, serErr = Sera.Serialize(self._schema, data)
	if not serialized then
		warn(`[Horus] Serialization failed on '{self._remoteName}': {serErr}`)
		return
	end

	local seqId, ciphertext, tag = SessionManager:Encrypt(session, serialized)
	self._remote:FireClient(player, seqId, ciphertext, tag)
end

function RemoteEventsServer:FireAll(...: any)
	for _, player in Players:GetPlayers() do
		if SessionManager:GetSession(player) then
			self:Fire(player, ...)
		end
	end
end

function RemoteEventsServer:FireFor(players: { Player }, ...: any)
	for _, player in players do
		self:Fire(player, ...)
	end
end

function RemoteEventsServer:FireAllExcept(excludePlayer: Player, ...: any)
	for _, player in Players:GetPlayers() do
		if player ~= excludePlayer and SessionManager:GetSession(player) then
			self:Fire(player, ...)
		end
	end
end

function RemoteEventsServer:OnEvent(callback: (Player, ...any) -> ())
	self._isSignalConnected = true
	
	return self._signal:Connect(callback)
end

return RemoteEventsServer
