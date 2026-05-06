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
		-- Don't add ourselves, and only add people who are currently alive
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
		-- Nobody is left alive, just look at the map center
		camera.CameraSubject = nil
		return
	end

	-- Wrap around the list if we click out of bounds
	if spectatingIndex > #alivePlayers then spectatingIndex = 1 end
	if spectatingIndex < 1 then spectatingIndex = #alivePlayers end

	local targetPlayer = alivePlayers[spectatingIndex]
	if targetPlayer and targetPlayer.Character then
		local targetHum = targetPlayer.Character:FindFirstChild("Humanoid")
		if targetHum then
			camera.CameraSubject = targetHum
			-- (Optional) Fire a BindableEvent here to tell your UI to show "SPECTATING: [Name]"
		end
	end
end

-----------------------------
-- MAIN LOGIC --
-----------------------------
player.CharacterAdded:Connect(function(char)
	isDead = false

	-- THE RESET: 
	-- When the round starts and we respawn, snap the camera back to our own body natively
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = char:WaitForChild("Humanoid")

	local hum = char:WaitForChild("Humanoid")

	hum.Died:Connect(function()
		isDead = true

		-- 1. THE DEATH CAM (Look at the goofy ragdoll)
		local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		if rootPart then
			camera.CameraSubject = rootPart
		end

		-- Wait 3 seconds to enjoy the physics
		task.wait(3)

		-- 2. ENTER SPECTATOR MODE
		if isDead then
			updateSpectateCamera()
		end
	end)
end)

-- 3. CYCLE PLAYERS WITH CLICKS (Left/Right Click)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isDead then return end

	-- Only allow cycling if the 3 second death cam is over
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