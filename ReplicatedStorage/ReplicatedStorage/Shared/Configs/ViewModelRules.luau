local ViewModelRules = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponModulesFolder = sharedFolder:WaitForChild("Weapons")

local function getWeaponStats(weaponName)
	local moduleNode = weaponModulesFolder:FindFirstChild(weaponName)
	if not moduleNode then
		return nil
	end

	local weaponModule = require(moduleNode)
	return weaponModule.Stats
end

local function hasTrait(stats, traitName)
	if not stats or not stats.Traits then
		return false
	end

	for _, trait in ipairs(stats.Traits) do
		if trait == traitName then
			return true
		end
	end

	return false
end

function ViewModelRules.GetWeaponStats(weaponName)
	return getWeaponStats(weaponName)
end

function ViewModelRules.HasTrait(weaponName, traitName)
	return hasTrait(getWeaponStats(weaponName), traitName)
end

function ViewModelRules.GetFireRate(weaponName)
	local stats = getWeaponStats(weaponName)
	if not stats then
		return 0.2
	end

	local fireRate = stats["Fire-Rate"] or stats.FireRate
	if type(fireRate) ~= "number" or fireRate <= 0 then
		return 0.2
	end

	return math.max(fireRate, 0.05)
end

function ViewModelRules.IsAutomaticWeapon(weaponName)
	local stats = getWeaponStats(weaponName)
	if not stats then
		return false
	end

	return hasTrait(stats, "Full-Automatic") or hasTrait(stats, "Burst Fire")
end

function ViewModelRules.GetViewModelSlot(weaponName, handName)
	local stats = getWeaponStats(weaponName)

	if not stats then
		return "Current"
	end

	local isTwoHanded = stats.DualWieldable == false or hasTrait(stats, "Two-Handed")
	if isTwoHanded then
		return "Current"
	end

	if handName == "Left" then
		return "Other"
	end

	return "Current"
end

function ViewModelRules.IsTwoHanded(weaponName)
	local stats = getWeaponStats(weaponName)
	if not stats then
		return false
	end

	return stats.DualWieldable == false or hasTrait(stats, "Two-Handed")
end

return ViewModelRules
