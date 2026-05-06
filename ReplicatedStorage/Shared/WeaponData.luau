local replicatedStorage = game:GetService("ReplicatedStorage")
local sharedModules = replicatedStorage:WaitForChild("Shared")
local BulletsData = require(sharedModules:WaitForChild("BulletsData"))

local WeaponData = {
	Pistol = {
		DisplayName = "9mm Pistol",
		FireRate = 0.1, -- seconds between shots
		AmmoType = BulletsData['9mm'],
		Magazine = 15,
		RecoilX = 8,
		RecoilY = 3,
		Spread = 2,
		SpreadIncrease = 1.5,
		SpreadDecay = 20, -- per second
		Model = "rbxassetid://...",
		Sound_Fire = "rbxassetid://...",
		Icon = "rbxassetid://93770874297975",
		Category = "Pistol",
		DualWieldable = true, -- NEW!
	},
	Rifle = {
		DisplayName = "Assault Rifle",
		FireRate = 0.12,
		AmmoType = BulletsData["5.56mm"],
		Magazine = 30,
		RecoilX = 12,
		RecoilY = 4,
		Spread = 3,
		SpreadIncrease = 2,
		SpreadDecay = 15,
		Model = "...",
		Sound_Fire = "...",
		Category = "Rifle",
		DualWieldable = true, -- NEW!
	},
	Shotgun = {
		DisplayName = "Combat Shotgun",
		FireRate = 0.8,
		AmmoType = BulletsData["12ga"],
		Magazine = 8,
		RecoilX = 20,
		RecoilY = 10,
		Spread = 25,
		PelletCount = 8,
		Model = "...",
		Sound_Fire = "...",
		Category = "Shotgun",
		DualWieldable = true, -- NEW!
	}
	-- Add Sniper, RocketLauncher, Knife following this pattern
}

return WeaponData