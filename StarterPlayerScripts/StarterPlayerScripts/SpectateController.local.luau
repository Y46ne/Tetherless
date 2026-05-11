local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

local isDead = false
local spectatingIndex = 1
local alivePlayers = {}

-----------------------------
-- HELPER FUNCTIONS --
-----------------------------
local function getAlivePlayers()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local hum = p.Character:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(list, p)
			end
		end
	end
	return list
end

local function updateSpectateCamera()
	alivePlayers = getAlivePlayers()

	if #alivePlayers == 0 then
		camera.CameraSubject = nil
		return
	end

	if spectatingIndex > #alivePlayers then spectatingIndex = 1 end
	if spectatingIndex < 1 then spectatingIndex = #alivePlayers end

	local targetPlayer = alivePlayers[spectatingIndex]
	if targetPlayer and targetPlayer.Character then
		local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
		if targetHum then
			camera.CameraSubject = targetHum
		end
	end
end

-----------------------------
-- MAIN LOGIC --
-----------------------------
player.CharacterAdded:Connect(function(char)
	isDead = false

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = char:WaitForChild("Humanoid")

	local hum = char:WaitForChild("Humanoid")

	hum.Died:Connect(function()
		isDead = true

		char:SetAttribute("RightWeapon", "None")
		char:SetAttribute("LeftWeapon", "None")

		local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		if rootPart then
			camera.CameraSubject = rootPart
		end

		task.wait(3)

		if isDead then
			updateSpectateCamera()
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isDead then return end

	if #getAlivePlayers() > 0 then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			spectatingIndex = spectatingIndex + 1
			updateSpectateCamera()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			spectatingIndex = spectatingIndex - 1
			updateSpectateCamera()
		end
	end
end)