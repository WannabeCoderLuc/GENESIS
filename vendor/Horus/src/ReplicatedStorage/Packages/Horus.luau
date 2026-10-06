--!optimize 2
--!native
--!strict

local RunService = game:GetService("RunService")

export type Horus = {
    Start: (self: Horus, ...Instance) -> (),
    StartComponents: (self: Horus, ...Instance) -> (),
    
    GetRemoteEvent: (self: Horus, serviceName: string, remoteName: string, schema: any) -> any,
    GetRemoteFunction: (self: Horus, serviceName: string, remoteName: string, requestSchema: any, responseSchema: any) -> any,
    WaitForSession: (self: Horus, player: Player?) -> any,
    
    IsServerLoaded: (self: Horus) -> boolean,
    IsClientLoaded: (self: Horus, player: Player?) -> boolean,
    IsPersistentLoaded: (self: Horus) -> boolean,
    WaitForLoadedClient: (self: Horus, player: Player) -> boolean,
    GetServerLoadedTimestamp: (self: Horus) -> number,
    
    Sera: any,
}

if RunService:IsServer() then
	return require("@game/ServerScriptService/Horus/Server") :: Horus
else
	return require("@self/Client") :: Horus
end