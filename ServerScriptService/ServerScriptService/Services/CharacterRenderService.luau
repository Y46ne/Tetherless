local CharacterRenderService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponsFolder = sharedFolder:WaitForChild("Weapons")
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local weaponModelsFolder = assetsFolder:WaitForChild("Weapons")

-- Store viewmodel data per player
local playerViewmodels = {}

-- Get or create RemoteEvent for viewmodel replication
local function getViewmodelReplicaEvent()
	local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end

	local viewmodelReplicaEvent = remoteEvents:FindFirstChild("ReplicateViewmodel")
	if not viewmodelReplicaEvent then
		viewmodelReplicaEvent = Instance.new("RemoteEvent")
		viewmodelReplicaEvent.Name = "ReplicateViewmodel"
		viewmodelReplicaEvent.Parent = remoteEvents
	end

	return viewmodelReplicaEvent
end

-- Create and update replicated viewmodel in world space for all players to see
local function updateReplicatedViewmodel(character, weaponName, viewmodelCFrame)
	if not character or not character.Parent then
		return
	end

	-- Create container if it doesn't exist
	local viewmodelContainer = character:FindFirstChild("_ReplicatedViewmodel")
	if not viewmodelContainer then
		viewmodelContainer = Instance.new("Folder")
		viewmodelContainer.Name = "_ReplicatedViewmodel"
		viewmodelContainer.Parent = character
	end

	-- Clean up old viewmodel
	for _, child in pairs(viewmodelContainer:GetChildren()) do
		child:Destroy()
	end

	-- Only create if weapon is equipped
	if not weaponName or weaponName == "None" then
		return
	end

	-- Get weapon template
	local weaponTemplate = weaponModelsFolder:FindFirstChild(weaponName)
	if not weaponTemplate then
		return
	end

	-- Clone the weapon to display at the viewmodel's position
	local weaponClone = weaponTemplate:Clone()
	weaponClone.Name = weaponName

	-- Configure all parts for visibility
	for _, part in pairs(weaponClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.LocalTransparencyModifier = 0
			-- Ensure parts are visible
			if part.Transparency > 0.5 then
				part.Transparency = 0.2
			end
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy()
		end
	end

	weaponClone.Parent = viewmodelContainer

	-- Position the weapon at the viewmodel's CFrame
	if weaponClone.PrimaryPart then
		weaponClone:PivotTo(viewmodelCFrame)
	end
end

-- Check if weapon is two-handed
local function isTwoHanded(weaponName)
	if not weaponName or weaponName == "None" then
		return false
	end
	local weaponModule = weaponsFolder:FindFirstChild(weaponName)
	if not weaponModule then
		return false
	end
	local stats = require(weaponModule).Stats
	if stats and (stats.DualWieldable == false or (stats.Traits and table.find(stats.Traits, "Two-Handed"))) then
		return true
	end
	return false
end

-- Hide character arms when weapons are equipped
local function updateArmVisibility(character)
	if not character or not character.Parent then
		return
	end

	local rightWeapon = character:GetAttribute("RightWeapon")
	local leftWeapon = character:GetAttribute("LeftWeapon")

	-- Find the arms
	local rightArm = character:FindFirstChild("Right Arm")
	local leftArm = character:FindFirstChild("Left Arm")

	-- Determine if two-handed weapon is equipped
	local isTwoHandedRight = isTwoHanded(rightWeapon)

	-- Hide right arm if right weapon is equipped
	if rightArm then
		if rightWeapon and rightWeapon ~= "None" then
			rightArm.Transparency = 1
			rightArm.LocalTransparencyModifier = 0
		else
			rightArm.Transparency = 0
			rightArm.LocalTransparencyModifier = 0
		end
	end

	-- Hide left arm if left weapon is equipped OR if right weapon is two-handed
	if leftArm then
		if (leftWeapon and leftWeapon ~= "None") or isTwoHandedRight then
			leftArm.Transparency = 1
			leftArm.LocalTransparencyModifier = 0
		else
			leftArm.Transparency = 0
			leftArm.LocalTransparencyModifier = 0
		end
	end
end

-- Create and position replicated weapon models for other players to see
-- Also creates visible arms that show the weapons
local function updateReplicatedWeapons(character)
	if not character or not character.Parent then
		return
	end

	local rightWeapon = character:GetAttribute("RightWeapon")
	local leftWeapon = character:GetAttribute("LeftWeapon")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	-- Clean up old replicated weapons
	local oldWeapons = character:FindFirstChild("_ReplicatedWeapons")
	if oldWeapons then
		oldWeapons:Destroy()
	end

	-- Only create if weapons are equipped
	if (not rightWeapon or rightWeapon == "None") and (not leftWeapon or leftWeapon == "None") then
		return
	end

	-- Create container for replicated weapons
	local weaponContainer = Instance.new("Folder")
	weaponContainer.Name = "_ReplicatedWeapons"
	weaponContainer.Parent = character

	-- Grip offset for weapon positioning
	local GRIP_OFFSET = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180))

	-- Create right weapon replica
	if rightWeapon and rightWeapon ~= "None" then
		local weaponTemplate = weaponModelsFolder:FindFirstChild(rightWeapon)
		if weaponTemplate then
			local rightWeaponClone = weaponTemplate:Clone()
			rightWeaponClone.Name = "RightWeapon"

			-- Ensure all parts are properly configured for visibility
			for _, part in pairs(rightWeaponClone:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.LocalTransparencyModifier = 0
					-- Keep original transparency but ensure visible
					if part.Transparency > 0.5 then
						part.Transparency = 0.3
					end
				elseif part:IsA("Script") or part:IsA("LocalScript") then
					part:Destroy()
				end
			end

			rightWeaponClone.Parent = weaponContainer

			-- Position weapon on right arm
			local rightArm = character:FindFirstChild("Right Arm")
			if rightArm and rightWeaponClone.PrimaryPart then
				rightWeaponClone:PivotTo(rightArm.CFrame * GRIP_OFFSET)
			end
		end
	end

	-- Create left weapon replica (only if dual wielding one-handed weapons)
	if leftWeapon and leftWeapon ~= "None" and not isTwoHanded(rightWeapon) then
		local weaponTemplate = weaponModelsFolder:FindFirstChild(leftWeapon)
		if weaponTemplate then
			local leftWeaponClone = weaponTemplate:Clone()
			leftWeaponClone.Name = "LeftWeapon"

			-- Ensure all parts are properly configured for visibility
			for _, part in pairs(leftWeaponClone:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
					part.LocalTransparencyModifier = 0
					-- Keep original transparency but ensure visible
					if part.Transparency > 0.5 then
						part.Transparency = 0.3
					end
				elseif part:IsA("Script") or part:IsA("LocalScript") then
					part:Destroy()
				end
			end

			leftWeaponClone.Parent = weaponContainer

			-- Position weapon on left arm
			local leftArm = character:FindFirstChild("Left Arm")
			if leftArm and leftWeaponClone.PrimaryPart then
				leftWeaponClone:PivotTo(leftArm.CFrame * GRIP_OFFSET)
			end
		end
	end
end

-- Setup character to handle arm visibility and weapon replication
local function setupCharacter(character, player)
	if not character or not character.Parent then
		return
	end

	-- Initial update
	updateArmVisibility(character)
	updateReplicatedWeapons(character)

	-- Listen to weapon changes
	character:GetAttributeChangedSignal("RightWeapon"):Connect(function()
		updateArmVisibility(character)
		updateReplicatedWeapons(character)
	end)

	character:GetAttributeChangedSignal("LeftWeapon"):Connect(function()
		updateArmVisibility(character)
		updateReplicatedWeapons(character)
	end)

	-- Periodically ensure arms stay hidden (in case something resets them)
	task.spawn(function()
		while character and character.Parent do
			task.wait(1)
			updateArmVisibility(character)
		end
	end)

	-- Continuously update weapon positions for smooth movement
	task.spawn(function()
		local GRIP_OFFSET = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180))

		while character and character.Parent do
			local weapons = character:FindFirstChild("_ReplicatedWeapons")
			if weapons then
				-- Update right weapon position
				local rightWeapon = weapons:FindFirstChild("RightWeapon")
				local rightArm = character:FindFirstChild("Right Arm")
				if rightWeapon and rightArm and rightWeapon.PrimaryPart then
					rightWeapon:PivotTo(rightArm.CFrame * GRIP_OFFSET)
				end

				-- Update left weapon position
				local leftWeapon = weapons:FindFirstChild("LeftWeapon")
				local leftArm = character:FindFirstChild("Left Arm")
				if leftWeapon and leftArm and leftWeapon.PrimaryPart then
					leftWeapon:PivotTo(leftArm.CFrame * GRIP_OFFSET)
				end
			end
			task.wait(0.05) -- Update 20 times per second (smooth enough)
		end
	end)
end

function CharacterRenderService.Init()
	-- Setup viewmodel replication event listener
	local viewmodelReplicaEvent = getViewmodelReplicaEvent()
	viewmodelReplicaEvent.OnServerEvent:Connect(function(player, weaponName, viewmodelCFrame)
		if player.Character then
			updateReplicatedViewmodel(player.Character, weaponName, viewmodelCFrame)
		end
	end)

	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			setupCharacter(player.Character, player)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(character, player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local character = player.Character
		if character then
			local weapons = character:FindFirstChild("_ReplicatedWeapons")
			if weapons then
				weapons:Destroy()
			end
			local viewmodel = character:FindFirstChild("_ReplicatedViewmodel")
			if viewmodel then
				viewmodel:Destroy()
			end
		end
		playerViewmodels[player] = nil
	end)
end

return CharacterRenderService
