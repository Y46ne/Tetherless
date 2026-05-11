local SpectatorController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local spectateEvent = remoteEvents:WaitForChild("SpectatePlayer")
local stopEvent = remoteEvents:WaitForChild("StopSpectating")

local currentTarget = nil

local function followTarget(targetPlayer)
	if not targetPlayer or not targetPlayer.Character then
		return
	end
	local char = targetPlayer.Character
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if humanoid then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		currentTarget = targetPlayer
	elseif root then
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = root.CFrame * CFrame.new(0, 5, -10)
		currentTarget = targetPlayer
	end
end

local function stopSpectating()
	-- Try to restore camera to player's own character if exists
	local myChar = player.Character
	if myChar and myChar:FindFirstChildOfClass("Humanoid") then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = myChar:FindFirstChildOfClass("Humanoid")
	else
		camera.CameraType = Enum.CameraType.Custom
		currentTarget = nil
	end
end

spectateEvent.OnClientEvent:Connect(function(targetName)
	if not targetName then
		-- No valid target; do nothing
		return
	end
	local targetPlayer = Players:FindFirstChild(targetName)
	if not targetPlayer then
		return
	end
	followTarget(targetPlayer)
end)

stopEvent.OnClientEvent:Connect(function()
	stopSpectating()
end)

-- If our own character spawns, stop spectating
player.CharacterAdded:Connect(function(char)
	stopSpectating()
end)

return SpectatorController
