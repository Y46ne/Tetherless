local replicatedStorage = game:GetService("ReplicatedStorage")
local shared = replicatedStorage:WaitForChild("Shared")
local configs = shared:WaitForChild("Configs")
local BulletsData = require(configs:WaitForChild("BulletsConfig"))

local WeaponConfig = {
	Pistol = {
		DisplayName = "9mm Pistol",
		FireRate = 0.1,
		AmmoType = BulletsData["9mm"],
		Magazine = 15,
		RecoilX = 8,
		RecoilY = 3,
		Spread = 2,
		SpreadIncrease = 1.5,
		SpreadDecay = 20,
		CameraRecoilX = 3,
		CameraRecoilY = -6,
		CameraRecoilRecovery = 0.15,
		Model = "rbxassetid://...",
		Sound_Fire = "rbxassetid://...",
		Icon = "rbxassetid://93770874297975",
		Category = "Pistol",
		DualWieldable = true,
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
		CameraRecoilX = 4,
		CameraRecoilY = -8,
		CameraRecoilRecovery = 0.12,
		Model = "...",
		Sound_Fire = "...",
		Category = "Rifle",
		DualWieldable = true,
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
		CameraRecoilX = 8,
		CameraRecoilY = -12,
		CameraRecoilRecovery = 0.2,
		Model = "...",
		Sound_Fire = "...",
		Category = "Shotgun",
		DualWieldable = true,
	},
}

return WeaponConfig
