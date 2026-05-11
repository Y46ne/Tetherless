local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modules = ReplicatedStorage:WaitForChild("Modules")
local Signal = require(modules:WaitForChild("Signal"))

local EventBus = {}
local signals = {}

function EventBus.Get(name)
	if not signals[name] then
		signals[name] = Signal.new()
	end
	return signals[name]
end

return EventBus
