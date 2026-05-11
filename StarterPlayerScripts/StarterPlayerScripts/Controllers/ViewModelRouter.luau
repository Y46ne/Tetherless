local ViewModelRouter = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponsFolder = sharedFolder:WaitForChild("Weapons")

local player = Players.LocalPlayer

-- Get weapon stats to determine if two-handed
local function getWeaponStats(weaponName)
	if not weaponName or weaponName == "None" then
		return nil
	end
	local weaponModule = weaponsFolder:FindFirstChild(weaponName)
	if not weaponModule then
		return nil
	end
	return require(weaponModule).Stats
end

-- Check if weapon has a specific trait
local function hasTrait(weaponName, trait)
	local stats = getWeaponStats(weaponName)
	if not stats or not stats.Traits then
		return false
	end
	for _, t in ipairs(stats.Traits) do
		if t == trait then
			return true
		end
	end
	return false
end

-- Check if weapon is two-handed (either DualWieldable=false or has Two-Handed trait)
local function isTwoHanded(weaponName)
	local stats = getWeaponStats(weaponName)
	if not stats then
		return false
	end

	-- Two-handed if explicitly marked or DualWieldable is false
	if hasTrait(weaponName, "Two-Handed") or stats.DualWieldable == false then
		return true
	end
	return false
end

-- Determine which viewmodel slot a weapon should use
function ViewModelRouter.GetViewModelSlot(weaponName, hand)
	-- Two-handed always goes to Current
	if isTwoHanded(weaponName) then
		return "Current"
	end

	-- One-handed: right hand goes to Current, left hand goes to Other
	if hand == "Right" then
		return "Current"
	else
		return "Other"
	end
end

-- Update character attributes to track which weapon goes to which slot
function ViewModelRouter.UpdateViewModelRouting(character)
	if not character then
		return
	end

	local rightWeapon = character:GetAttribute("RightWeapon")
	local leftWeapon = character:GetAttribute("LeftWeapon")

	-- If right weapon is two-handed, use OtherViewModel for that large weapon
	if rightWeapon and rightWeapon ~= "None" and isTwoHanded(rightWeapon) then
		-- Two-handed weapon (AK, Rocket Launcher, etc.) goes to OtherViewModel
		character:SetAttribute("CurrentViewModelWeapon", nil)
		character:SetAttribute("CurrentViewModelHand", nil)
		character:SetAttribute("OtherViewModelWeapon", rightWeapon)
		character:SetAttribute("OtherViewModelHand", "Right")
		character:SetAttribute("ShowLeftArm", false)
	-- If we have dual one-handed weapons, use CurrentViewModel with both arms
	elseif rightWeapon and rightWeapon ~= "None" and leftWeapon and leftWeapon ~= "None" then
		character:SetAttribute("CurrentViewModelWeapon", rightWeapon)
		character:SetAttribute("CurrentViewModelHand", "Right")
		character:SetAttribute("OtherViewModelWeapon", leftWeapon)
		character:SetAttribute("OtherViewModelHand", "Left")
		character:SetAttribute("ShowLeftArm", true)
	-- If only right weapon (one-handed), use CurrentViewModel with only right arm
	elseif rightWeapon and rightWeapon ~= "None" then
		character:SetAttribute("CurrentViewModelWeapon", rightWeapon)
		character:SetAttribute("CurrentViewModelHand", "Right")
		character:SetAttribute("OtherViewModelWeapon", nil)
		character:SetAttribute("OtherViewModelHand", nil)
		character:SetAttribute("ShowLeftArm", false)
	-- If only left weapon, use CurrentViewModel with only right arm (weapon stays on right)
	elseif leftWeapon and leftWeapon ~= "None" then
		character:SetAttribute("CurrentViewModelWeapon", leftWeapon)
		character:SetAttribute("CurrentViewModelHand", "Left")
		character:SetAttribute("OtherViewModelWeapon", nil)
		character:SetAttribute("OtherViewModelHand", nil)
		character:SetAttribute("ShowLeftArm", false)
	-- Nothing equipped
	else
		character:SetAttribute("CurrentViewModelWeapon", nil)
		character:SetAttribute("CurrentViewModelHand", nil)
		character:SetAttribute("OtherViewModelWeapon", nil)
		character:SetAttribute("OtherViewModelHand", nil)
		character:SetAttribute("ShowLeftArm", false)
	end
end

function ViewModelRouter.Init()
	player.CharacterAdded:Connect(function(character)
		character:GetAttributeChangedSignal("RightWeapon"):Connect(function()
			ViewModelRouter.UpdateViewModelRouting(character)
		end)
		character:GetAttributeChangedSignal("LeftWeapon"):Connect(function()
			ViewModelRouter.UpdateViewModelRouting(character)
		end)
		ViewModelRouter.UpdateViewModelRouting(character)
	end)

	if player.Character then
		ViewModelRouter.UpdateViewModelRouting(player.Character)
	end
end

return ViewModelRouter
