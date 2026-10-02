local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsClient() then
	return {} :: any
end

local Packages = script.Parent.Parent
local Networker = require(Packages.Networker)
local Value = require(script.Parent.Value)
local GameStateTypedTypes = require(script.Parent.GameStateTypedTypes)

type StateOptions<T> = GameStateTypedTypes.StateOptions<T>

local GameStateTypedServer = {
	_initialized = false,
	_subscribers = {} :: { [Player]: boolean },
}

--[=[
	@class GameStateTypedServer
	Owns one session-wide state tree and replicates its changes to every subscribed client.
]=]
function GameStateTypedServer:init<T>(options: StateOptions<T>): Value.Value<T>
	assert(RunService:IsServer(), "GameStateTypedServer can only be used on the server.")
	assert(not self._initialized, "GameStateTypedServer has already been initialized.")
	self._initialized = true
	Value.shouldRecordPath = true

	local replicate = function(replicateType: string, path: { string | number }, ...)
		local recipients = {}
		for player in self._subscribers do
			if player.Parent == Players then
				table.insert(recipients, player)
			end
		end

		if #recipients > 0 then
			self.networker:fire(recipients, replicateType, path, ...)
		end
	end
	self.data = Value.new(options.template, nil, nil, replicate :: any)

	self.networker = Networker.server.new("GameStateTyped", self, { self.getInitialState })
	Players.PlayerRemoving:Connect(function(player: Player)
		self._subscribers[player] = nil
	end)

	return self.data
end

-- The client can only request a snapshot; it cannot mutate server state.
-- Registering after reading the snapshot ensures later mutations are sent as deltas.
function GameStateTypedServer.getInitialState(self: GameStateTypedServer<any>, player: Player): any
	local snapshot = self.data()
	self._subscribers[player] = true
	return snapshot
end

export type GameStateTypedServer<T> = typeof(GameStateTypedServer) & {
	networker: Networker.Server,
	data: Value.Value<T>,
}

return GameStateTypedServer
