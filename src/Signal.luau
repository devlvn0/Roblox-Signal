--!strict

--[[

Name: Signal
Authors: devlvn
Created: 06/10/2025
Description: Small and fast library for creating signals. Nearly identical to roblox' RBXScriptSignal.

Version: 1.1.0

]]

-- Services
local RunService = game:GetService("RunService")

-- Types
export type Signal = {
	Connect: (self: Signal, func: (any) -> ()) -> Connection,
	ConnectParallel: (self: Signal, func: (any) -> ()) -> Connection,
	ConnectCondition: <T>(self: Signal, condition: T, func: (any) -> ()) -> Connection,
	Once: (self: Signal, func: (any) -> ()) -> Connection,
	Wait: (self: Signal, timeOut: number?) -> any
}
export type Connection = {
	Disconnect: (self: Connection) -> (),
}
type InternalConnection = {
	Disconnect: (self: Connection) -> (),
	ConnectToDisconnection: (self: InternalConnection, func: () -> ()) -> (),
}
type InternalConnectionData = {
	func: (any) -> (),
	disconnected: boolean,
}

-- Signal
local signal = {}

function signal.new(): (Signal, (any) -> (), () -> ())
	local functions: {[(any) -> ()]: InternalConnectionData} = {}
	local waitingFunctions: {[(any) -> ()]: InternalConnectionData} = {}

	local destroyed: boolean
	local firing: boolean

	-- Internal Connect Function
	local function internalConnection(self: Signal, func: (any) -> ()): InternalConnection
		assert(destroyed ~= true, "Signal was destroyed, can't create any new connections!")
		
		local newConnection: InternalConnectionData = {
			func = func,
			disconnected = false,
		}

		if firing and not functions[func] then
			waitingFunctions[func] = newConnection
		else
			functions[func] = newConnection
		end

		local disconnectFunctions: {() -> ()} = {}
		local function disconnect(self: Connection)
			newConnection.disconnected = true
			functions[func] = nil
			waitingFunctions[func] = nil

			for _, func: () -> () in disconnectFunctions do
				func()
			end
		end

		local function connectToDisconnection(self: InternalConnection, func: () -> ())
			table.insert(disconnectFunctions, func)
		end

		return {
			Disconnect = disconnect,
			ConnectToDisconnection = connectToDisconnection,
		}
	end

	-- Connects a function to a signal
	local function connect(self: Signal, func: (any) -> ()): Connection
		local connFuncs = internalConnection(self, func)

		return {
			Disconnect = connFuncs.Disconnect,
		}
	end

	-- Connects a function to a signal and executes it in parallel
	local function connectParallel(self: Signal, func: (any) -> ()): Connection
		local returnedValues: {}

		local execCoroutine: thread = coroutine.create(function()
			task.desynchronize()
			while true do
				coroutine.yield()
				task.desynchronize()
				func()
			end
		end)

		local connection = internalConnection(self, function(...)
			returnedValues = {...}
			coroutine.resume(execCoroutine)
		end)
		
		connection:ConnectToDisconnection(function()
			coroutine.close(execCoroutine)
		end)
		
		return {
			Disconnect = connection.Disconnect,
		}
	end

	-- Connects a function to a signal, automatically disconnects it once the signal fired
	local function connectOnce(self: Signal, func: (any) -> ()): Connection
		local connection: Connection
		connection = connect(self, function(...)
			func(...)
			connection:Disconnect()
		end)
		return connection
	end
	
	-- Connects a function to a signal, automatically disconnects it when a set condition reaches true
	local function connectCondition<T>(self: Signal, condition: T, func: (any) -> ()): Connection
		local connection: Connection
		connection = connect(self, function(...)
			func(...)
			
			if condition then
				connection:Disconnect()
			end
		end)
		return connection
	end

	local function connectAndWait(self: Signal, timeOut: number?): any
		local called: boolean
		local returnedValues: {any}

		local connection = connectOnce(self, function(...)
			returnedValues = {...}
			called = true
		end)

		local waitedTime = 0
		while not called and (timeOut and waitedTime < timeOut) do
			waitedTime += RunService.Heartbeat:Wait()
		end

		if not called then
			if connection then
				connection:Disconnect()
			end

			warn("Connection wait time ran out, signal was not called in time!")
			return nil
		end

		return table.unpack(returnedValues)
	end

	local function fire(...: any): ()
		firing = true

		for func: (any) -> (), _ in functions do
			func(...)
		end 

		firing = false

		for func: (any) -> (), connection: InternalConnectionData in waitingFunctions do
			functions[func] = connection
		end
		table.clear(waitingFunctions)
	end

	local function destroy(): ()
		destroyed = true
		table.clear(functions)
		table.clear(waitingFunctions)
	end

	return {
		Connect = connect,
		ConnectParallel = connectParallel,
		ConnectCondition = connectCondition,
		Once = connectOnce,
		Wait = connectAndWait,
	}, fire, destroy
end

return signal
