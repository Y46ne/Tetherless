local ServerNetwork = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local shared = ReplicatedStorage:FindFirstChild("Shared")

local updateHUD = shared and shared:FindFirstChild("UpdateHUD")

local function fireRemoteIfExists(remoteName, statusText, timerValue)
	if not remoteEvents then
		return
	end
	local remoteEvent = remoteEvents:FindFirstChild(remoteName)
	if not remoteEvent then
		return
	end

	pcall(function()
		remoteEvent:FireAllClients(statusText, timerValue)
	end)
end

function ServerNetwork.BroadcastMatchStatus(statusText, timerValue)
	-- Support both naming variants used across this project.
	fireRemoteIfExists("MatchUpdate", statusText, timerValue)
	fireRemoteIfExists("MatchStatus", statusText, timerValue)

	-- Backwards compatibility with an existing BindableEvent used in this project
	if updateHUD and updateHUD.Fire then
		pcall(function()
			updateHUD:Fire(statusText, timerValue)
		end)
	end
end

return ServerNetwork
