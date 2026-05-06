local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WeaponData = require(ReplicatedStorage.Shared:WaitForChild("WeaponData"))

local WeaponState = {
	["AmmoInventory"] = {}
}

function WeaponState.getAmmo(weaponName)
	return WeaponState.AmmoInventory[weaponName]
end

function WeaponState.resetAmmo(weaponName, isOffhand)
	local stats = WeaponData[weaponName]
	if stats then
		if not WeaponState.AmmoInventory[weaponName] then 
			WeaponState.AmmoInventory[weaponName] = {Mag = 0, LeftMag = 0, IsDual = false} 
		end

		if isOffhand then
			WeaponState.AmmoInventory[weaponName].LeftMag = stats.Magazine
			WeaponState.AmmoInventory[weaponName].IsDual = true
		else
			WeaponState.AmmoInventory[weaponName].Mag = stats.Magazine
			WeaponState.AmmoInventory[weaponName].IsDual = false 
		end
	end
end

return WeaponState