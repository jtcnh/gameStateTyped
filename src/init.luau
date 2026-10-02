local RunService = game:GetService("RunService")

local GameStateTypedClient = require(script.GameStateTypedClient)
local GameStateTypedServer = require(script.GameStateTypedServer)
local GameStateTypedTypes = require(script.GameStateTypedTypes)
local Value = require(script.Value)

export type Client<T> = GameStateTypedClient.GameStateTypedClient<T>
export type Server<T> = GameStateTypedServer.GameStateTypedServer<T>
export type StateOptions<T> = GameStateTypedTypes.StateOptions<T>
export type Value<T> = Value.Value<T>

return function<T>(options: StateOptions<T>)
	return {
		client = (if RunService:IsClient() then GameStateTypedClient:init(options.template) else {}) :: Value<T>,
		server = (if RunService:IsServer() then GameStateTypedServer:init(options) else {}) :: Value<T>,
	}
end
