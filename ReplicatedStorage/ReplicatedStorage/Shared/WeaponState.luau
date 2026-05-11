local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local weaponModulesFolder = shared:WaitForChild("Weapons") 

local WeaponState = {
	["AmmoInventory"] = {},
}

function WeaponState.getAmmo(weaponName)
	return WeaponState.AmmoInventory[weaponName]
end

function WeaponState.resetAmmo(weaponName)
	local moduleNode = weaponModulesFolder:FindFirstChild(weaponName)
	if not moduleNode then return end

	local weaponModule = require(moduleNode)
	local stats = weaponModule.Stats

	if stats then
		if not WeaponState.AmmoInventory[weaponName] then
			WeaponState.AmmoInventory[weaponName] = { Mag = 0 }
		end

		WeaponState.AmmoInventory[weaponName].Mag = stats.Magazine
	end
end

return WeaponState