local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local weaponModulesFolder = shared:WaitForChild("Weapons")

-- Keyed by hand ("Right" / "Left") so dual-wielding the same weapon type
-- gives each hand its own independent ammo count.
local AmmoInventory = {
	Right = { Mag = 0 },
	Left  = { Mag = 0 },
}

local WeaponState = {}

function WeaponState.getAmmo(hand)
	return AmmoInventory[hand]
end

function WeaponState.resetAmmo(hand, weaponName)
	local moduleNode = weaponModulesFolder:FindFirstChild(weaponName)
	if not moduleNode then return end

	local weaponModule = require(moduleNode)
	local stats = weaponModule.Stats
	if stats then
		AmmoInventory[hand] = { Mag = stats.Magazine }
	end
end

return WeaponState
