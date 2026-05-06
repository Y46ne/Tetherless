local ServerNetwork = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local shared = ReplicatedStorage:FindFirstChild("Shared")

local matchEvent = remoteEvents and remoteEvents:FindFirstChild("MatchUpdate")
local updateHUD = shared and shared:FindFirstChild("UpdateHUD")

function ServerNetwork.BroadcastMatchStatus(statusText, timerValue)
	-- Fire a dedicated RemoteEvent if present
	if matchEvent then
		pcall(function()
			matchEvent:FireAllClients(statusText, timerValue)
		end)
	end

	-- Backwards compatibility with an existing BindableEvent used in this project
	if updateHUD and updateHUD.Fire then
		pcall(function()
			updateHUD:Fire(statusText, timerValue)
		end)
	end
end

return ServerNetwork
