-- CharacterRenderService
-- Attaches replicated weapon models to character arms so other players see the held weapon.
-- Weapons are welded to the arm bones, so they follow animation automatically with no update loop.
-- Arm pose animations are played client-side by WeaponController and auto-replicated by Roblox.

local CharacterRenderService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local weaponModelsFolder = assetsFolder:WaitForChild("Weapons")
local weaponsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons")

-- Initial grip offset applied once when the weapon is welded.
-- Adjust per-weapon if needed; the weld keeps it locked after this.
local GRIP_OFFSET = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180))

local function isTwoHanded(weaponName)
	if not weaponName or weaponName == "None" then
		return false
	end
	local node = weaponsFolder:FindFirstChild(weaponName)
	if not node then
		return false
	end
	local stats = require(node).Stats
	if not stats then
		return false
	end
	if stats.DualWieldable == false then
		return true
	end
	if stats.Traits then
		for _, t in ipairs(stats.Traits) do
			if t == "Two-Handed" then
				return true
			end
		end
	end
	return false
end

-- Clones a weapon model, strips scripts, disables collisions, and welds it to an arm.
-- The WeldConstraint keeps the weapon glued without any per-frame repositioning.
local function attachWeaponToArm(weaponName, arm, container)
	local template = weaponModelsFolder:FindFirstChild(weaponName)
	if not template or not arm then
		return
	end

	local clone = template:Clone()
	for _, part in ipairs(clone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = false
		elseif part:IsA("Script") or part:IsA("LocalScript") then
			part:Destroy()
		end
	end
	clone.Parent = container

	local primaryPart = clone.PrimaryPart
	if not primaryPart then
		return
	end

	-- Snap to grip position, then weld so it follows the arm's animation.
	clone:PivotTo(arm.CFrame * GRIP_OFFSET)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = arm
	weld.Part1 = primaryPart
	weld.Parent = primaryPart
end

-- Rebuilds the _ReplicatedWeapons folder whenever the character's equipped weapons change.
local function updateCharacterWeapons(character)
	local old = character:FindFirstChild("_ReplicatedWeapons")
	if old then
		old:Destroy()
	end

	local rightWeapon = character:GetAttribute("RightWeapon")
	local leftWeapon = character:GetAttribute("LeftWeapon")

	local hasRight = rightWeapon and rightWeapon ~= "None"
	local hasLeft = leftWeapon and leftWeapon ~= "None"
	if not hasRight and not hasLeft then
		return
	end

	local container = Instance.new("Folder")
	container.Name = "_ReplicatedWeapons"
	container.Parent = character

	if hasRight then
		local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
		attachWeaponToArm(rightWeapon, rightArm, container)
	end

	-- Left weapon only appears when dual-wielding two one-handed weapons.
	-- Two-handed weapons never have a separate left weapon slot.
	if hasLeft and not isTwoHanded(rightWeapon) then
		local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftHand")
		attachWeaponToArm(leftWeapon, leftArm, container)
	end
end

local function setupCharacter(character)
	updateCharacterWeapons(character)

	character:GetAttributeChangedSignal("RightWeapon"):Connect(function()
		updateCharacterWeapons(character)
	end)
	character:GetAttributeChangedSignal("LeftWeapon"):Connect(function()
		updateCharacterWeapons(character)
	end)
end

function CharacterRenderService.Init()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			setupCharacter(player.Character)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			setupCharacter(character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if player.Character then
			local weapons = player.Character:FindFirstChild("_ReplicatedWeapons")
			if weapons then
				weapons:Destroy()
			end
		end
	end)
end

return CharacterRenderService
