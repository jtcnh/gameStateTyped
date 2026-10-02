local RunService = game:GetService("RunService")

local Packages = script.Parent.Parent
local Networker = require(Packages.Networker)
local Value = require(script.Parent.Value)

if RunService:IsServer() then
	return {} :: any
end

local GameStateTypedClient = {
	hasLoaded = false,
	_pendingOperations = {} :: { () -> () },
}

function GameStateTypedClient.init<T>(self: GameStateTypedClient<T>, template: T)
	self.networker = Networker.client.new("GameStateTyped", self)

	if not RunService:IsRunning() then
		self:load(template)
	else
		self:load(self.networker:fetch("getInitialState"))
	end

	return self.data
end

function GameStateTypedClient.load<T>(self: GameStateTypedClient<T>, data: T)
	self.data = Value.new(data)
	self.hasLoaded = true
	for _, operation in self._pendingOperations do
		operation()
	end
	table.clear(self._pendingOperations)
end

function GameStateTypedClient.get<T>(self: GameStateTypedClient<T>, path: { string | number }): Value.Value<any>
	local current = self.data
	for i = #path, 2, -1 do
		local key = path[i]
		current = (current :: any)[key]
	end

	return (current :: any)[path[1]]
end

function GameStateTypedClient.set<T>(self: GameStateTypedClient<T>, path: { string | number }, value: any?)
	local operation = function()
		self:get(path)(value)
	end
	if not self.hasLoaded then
		table.insert(self._pendingOperations, operation)
	else
		operation()
	end
end

function GameStateTypedClient.insert<T>(self: GameStateTypedClient<T>, path: { string | number }, item: any, pos: number?)
	local operation = function()
		self:get(path).Insert(item, pos)
	end
	if not self.hasLoaded then
		table.insert(self._pendingOperations, operation)
	else
		operation()
	end
end

function GameStateTypedClient.remove<T>(self: GameStateTypedClient<T>, path: { string | number }, pos: number?)
	local operation = function()
		self:get(path).Remove(pos)
	end
	if not self.hasLoaded then
		table.insert(self._pendingOperations, operation)
	else
		operation()
	end
end

export type GameStateTypedClient<T> = typeof(GameStateTypedClient) & {
	hasLoaded: boolean,
	_pendingOperations: { () -> () },
	networker: Networker.Client,
	data: Value.Value<T>,
}

return GameStateTypedClient
