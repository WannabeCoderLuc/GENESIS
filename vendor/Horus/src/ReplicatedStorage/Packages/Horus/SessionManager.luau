--!optimize 2
--!native

local Cryptography = require("@game/ReplicatedStorage/Packages/Cryptography")
local Bindable = require("./_Index/Bindable")

local EdDSA = Cryptography.Verification.EdDSA
local X25519 = EdDSA.X25519
local CSPRNG = EdDSA.CSPRNG
local AEAD = Cryptography.Encryption.AEAD
local Blake3 = Cryptography.Hashing.Blake3

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local isServer = RunService:IsServer()

local HANDSHAKE_REMOTE_NAME = "__HorusHandshake"
local CHACHA_KEY_LENGTH = 32
local NONCE_LENGTH = 12
local X25519_PUBLIC_KEY_SIZE = 32

local deriveEncKey = Blake3.DeriveKey(buffer.fromstring("HorusSessionEncryptionKey"))
local deriveNonceSeed = Blake3.DeriveKey(buffer.fromstring("HorusSessionBaseNonce"))

export type Session = {
	EncKey: buffer,
	BaseNonce: buffer,
	SendSeq: number,
	RecvSeq: number,
}

local serverSessions: { [Player]: Session } = {}
local pendingMaskedKeys: { [Player]: buffer } = {}
local handshakeRatelimit: { [Player]: number } = {}
local clientSession: Session? = nil
local sessionReadySignal = Bindable.new()

local function concatBuffers(a: buffer, b: buffer): buffer
	local lenA = buffer.len(a)
	local lenB = buffer.len(b)
	local result = buffer.create(lenA + lenB)
	buffer.copy(result, 0, a, 0, lenA)
	buffer.copy(result, lenA, b, 0, lenB)

	return result
end

local function deriveSessionKeys(sharedSecret: buffer, player: Player): (buffer, buffer)
	local salt = buffer.fromstring(tostring(player.UserId))
	local material = concatBuffers(sharedSecret, salt)

	local _, encKey = deriveEncKey(material, CHACHA_KEY_LENGTH)
	local _, baseNonce = deriveNonceSeed(material, NONCE_LENGTH)

	return encKey, baseNonce
end

local function deriveNonce(baseNonce: buffer, seqId: number): buffer
	local nonce = buffer.create(NONCE_LENGTH)
	buffer.copy(nonce, 0, baseNonce, 0, 8)
	local baseWord = buffer.readu32(baseNonce, 8)
	buffer.writeu32(nonce, 8, bit32.bxor(baseWord, seqId))
	return nonce
end

local function scrubBuffer(buf: buffer)
	buffer.fill(buf, 0, 0, buffer.len(buf))
end

local SessionManager = {}

function SessionManager:GetSession(player: Player?): Session?
	if isServer then
		if player then
			return serverSessions[player]
		end
		return nil
	else
		return clientSession
	end
end

function SessionManager:WaitForSession(player: Player?): Session
	local session = self:GetSession(player)
	while not session do
		sessionReadySignal:Wait()
		session = self:GetSession(player)
	end
	return session
end

function SessionManager:Encrypt(session: Session, serializedData: buffer): (number, buffer, buffer)
	local seqId = session.SendSeq
	session.SendSeq += 1

	local nonce = deriveNonce(session.BaseNonce, seqId)
	local ciphertext, tag = AEAD.Encrypt(serializedData, session.EncKey, nonce)

	return seqId, ciphertext, tag
end

function SessionManager:Decrypt(session: Session, seqId: number, ciphertext: buffer, tag: buffer): (boolean, buffer?)
	if seqId <= session.RecvSeq then
		return false, nil
	end

	local nonce = deriveNonce(session.BaseNonce, seqId)
	local plaintext = AEAD.Decrypt(ciphertext, session.EncKey, nonce, tag)

	if plaintext then
		session.RecvSeq = seqId
		return true, plaintext
	end

	return false, nil
end

if isServer then
	local handshakeRemote = Instance.new("RemoteFunction")
	handshakeRemote.Name = HANDSHAKE_REMOTE_NAME
	handshakeRemote.Parent = ReplicatedStorage

	handshakeRemote.OnServerInvoke = function(player: Player, clientPublicKey: buffer?): any
		if serverSessions[player] then
			warn(`[Horus] Handshake rejected: {player.Name} already has an active session`)
			return false
		end

		local now = os.clock()
		local lastAttempt = handshakeRatelimit[player] or 0

		if clientPublicKey == nil then
			if now - lastAttempt < 1 then
				warn(`[Horus] Handshake rate limit exceeded for {player.Name}`)
				return false
			end
			handshakeRatelimit[player] = now

			local secretKey = CSPRNG.RandomBytes(32)
			local maskedKey = X25519.Mask(secretKey)
			scrubBuffer(secretKey)

			local serverPublicKey = X25519.PublicKey(maskedKey)
			pendingMaskedKeys[player] = maskedKey
			return serverPublicKey
		end

		if typeof(clientPublicKey) ~= "buffer" then
			warn(`[Horus] Invalid public key type from {player.Name}: {typeof(clientPublicKey)}`)
			return false
		end

		if buffer.len(clientPublicKey) ~= X25519_PUBLIC_KEY_SIZE then
			warn(`[Horus] Invalid public key size from {player.Name}: {buffer.len(clientPublicKey)}`)
			return false
		end

		local maskedKey = pendingMaskedKeys[player]
		if not maskedKey then
			warn(`[Horus] No pending keypair for {player.Name}`)
			return false
		end

		local ok, sharedSecret = pcall(X25519.Exchange, maskedKey, clientPublicKey)
		if not ok or not sharedSecret then
			warn(`[Horus] X25519 key exchange failed for {player.Name}`)
			pendingMaskedKeys[player] = nil
			return false
		end

		scrubBuffer(maskedKey)
		pendingMaskedKeys[player] = nil

		local encKey, baseNonce = deriveSessionKeys(sharedSecret, player)
		scrubBuffer(sharedSecret)

		serverSessions[player] = {
			EncKey = encKey,
			BaseNonce = baseNonce,
			SendSeq = 0,
			RecvSeq = -1,
		}

		sessionReadySignal:Fire()
		return true
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local session = serverSessions[player]
		if session then
			scrubBuffer(session.EncKey)
			scrubBuffer(session.BaseNonce)
			serverSessions[player] = nil
		end

		local pending = pendingMaskedKeys[player]
		if pending then
			scrubBuffer(pending)
			pendingMaskedKeys[player] = nil
		end

		handshakeRatelimit[player] = nil
	end)

else
	task.spawn(function()
		local handshakeRemote = ReplicatedStorage:WaitForChild(HANDSHAKE_REMOTE_NAME, 30) :: RemoteFunction
		if not handshakeRemote or not handshakeRemote:IsA("RemoteFunction") then
			warn("[Horus] Failed to find handshake RemoteFunction")
			return
		end

		local serverPublicKey = handshakeRemote:InvokeServer(nil)
		if not serverPublicKey or typeof(serverPublicKey) ~= "buffer" then
			warn("[Horus] Handshake Phase 1 failed: invalid public key response")
			return
		end

		local secretKey = CSPRNG.RandomBytes(32)
		local maskedKey = X25519.Mask(secretKey)
		scrubBuffer(secretKey)

		local clientPublicKey = X25519.PublicKey(maskedKey)

		local ok, sharedSecret = pcall(X25519.Exchange, maskedKey, serverPublicKey)
		if not ok or not sharedSecret then
			warn("[Horus] X25519 key exchange failed")
			scrubBuffer(maskedKey)
			return
		end

		scrubBuffer(maskedKey)

		local success = handshakeRemote:InvokeServer(clientPublicKey)
		if success ~= true then
			warn("[Horus] Handshake Phase 2 failed: server rejected public key")
			return
		end

		local encKey, baseNonce = deriveSessionKeys(sharedSecret, Players.LocalPlayer)
		scrubBuffer(sharedSecret)

		clientSession = {
			EncKey = encKey,
			BaseNonce = baseNonce,
			SendSeq = 0,
			RecvSeq = -1,
		}

		sessionReadySignal:Fire()
	end)
end

return SessionManager
