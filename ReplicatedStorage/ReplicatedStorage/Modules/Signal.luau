local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_connections = {},
		_waiters = {},
		_destroyed = false,
	}, Signal)
end

function Signal:Connect(callback)
	assert(not self._destroyed, "Cannot connect to a destroyed Signal")
	assert(type(callback) == "function", "Signal:Connect expects a function")

	local connection = {
		_connected = true,
		_signal = self,
		_callback = callback,
	}

	function connection.Disconnect(connectionSelf)
		if not connectionSelf._connected then
			return
		end

		connectionSelf._connected = false
		for index, item in ipairs(connectionSelf._signal._connections) do
			if item == connectionSelf then
				table.remove(connectionSelf._signal._connections, index)
				break
			end
		end
	end

	table.insert(self._connections, connection)

	return connection
end

function Signal:Once(callback)
	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

function Signal:Fire(...)
	if self._destroyed then
		return
	end

	for _, connection in ipairs(self._connections) do
		if connection._connected then
			coroutine.wrap(connection._callback)(...)
		end
	end

	while #self._waiters > 0 do
		local waiter = table.remove(self._waiters, 1)
		coroutine.wrap(waiter)(...)
	end
end

function Signal:Wait()
	if self._destroyed then
		return
	end

	local thread = coroutine.running()
	table.insert(self._waiters, function(...)
		coroutine.resume(thread, ...)
	end)

	return coroutine.yield()
end

function Signal:DisconnectAll()
	for _, connection in ipairs(self._connections) do
		connection._connected = false
	end
	self._connections = {}
	self._waiters = {}
end

function Signal:Destroy()
	self:DisconnectAll()
	self._destroyed = true
end

return Signal
