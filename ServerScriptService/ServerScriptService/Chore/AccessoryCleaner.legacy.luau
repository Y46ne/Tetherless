local Players = game:GetService("Players")

local function clearAccessories(character)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:RemoveAccessories()
	end

	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Accessory") then
			item:Destroy()
		end
	end
end

local function onPlayerAdded(player)
	player.CharacterAppearanceLoaded:Connect(function(character)
		clearAccessories(character)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
	if player.Character then
		clearAccessories(player.Character)
	end
end