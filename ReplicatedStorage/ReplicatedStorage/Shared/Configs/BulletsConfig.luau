local BulletsData = {
	["9mm"] = {
		name = "9mm",
		Icon = "rbxassetid://116575917819443",
		Damage = 7.5,
		MinDamage = 10,       -- Minimum damage at max range
		MaxRange = 250,       -- Distance where damage hits minimum
		MuzzleVelocity = 800, -- Speed of the bullet (Studs per second)
		GravityScale = 0.8,   -- How much workspace gravity pulls it down
		HeadshotMultiplier = 2.0,
	},
	["5.56mm"] = {
		name = "5.56mm",
		Icon = "rbxassetid://",
		Damage = 14,
		MinDamage = 15,
		MaxRange = 400,
		MuzzleVelocity = 1200,
		GravityScale = 0.5,
		HeadshotMultiplier = 1.5,
	},
	["12ga"] = {
		name = "12 Gauge",
		Icon = "rbxassetid://",
		Damage = 60,
		MinDamage = 5,
		MaxRange = 80,
		MuzzleVelocity = 600,
		GravityScale = 1.2,
		HeadshotMultiplier = 1.2,
	},
}

return BulletsData