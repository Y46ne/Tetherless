-- WeaponSounds
-- Maps every weapon name to its sound asset IDs and pitch.
-- Replace each "rbxassetid://89343784634356" with your actual Roblox sound asset ID.
-- SoundController reads this module automatically — no other changes needed.
--
-- Pitch: 1.0 is default. Higher = lighter/faster, lower = heavier/deeper.
-- Weapons that share the same base sound are grouped with a comment.

local WeaponSounds = {

	-- ── GROUP 1: RIFLE CRACK ──────────────────────────────────────────────────
	-- One gunshot sound, pitch-shifted per weapon.

	AK = {
		Fire  = "rbxassetid://97074441262170",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
	MAC10 = {
		Fire  = "rbxassetid://97074441262170",  -- same as AK
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.2,
	},
	Minigun = {
		Fire  = "rbxassetid://97074441262170",  -- same as AK
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.1,
	},
	RicochetRifle = {
		Fire  = "rbxassetid://97074441262170",  -- same as AK
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.9,
	},

	-- ── GROUP 2: PISTOL BANG ─────────────────────────────────────────────────

	Pistol = {
		Fire  = "rbxassetid://98725625576273",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
	Revolver = {
		Fire  = "rbxassetid://98725625576273",  -- same as Pistol
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.8,
	},
	HandCannon = {
		Fire  = "rbxassetid://98725625576273",  -- same as Pistol
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.65,
	},

	-- ── GROUP 3: ENERGY / ZAP ────────────────────────────────────────────────

	Taser = {
		Fire  = "rbxassetid://140717570350005",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
	Gamma = {
		Fire  = "rbxassetid://140717570350005",  -- same as Taser
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.8,
	},
	BeamLoad = {
		Fire  = "rbxassetid://140717570350005",  -- same as Taser
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.75,
	},
	Repulsar = {
		Fire  = "rbxassetid://140717570350005",  -- same as Taser
		Pitch = 0.7,
	},

	-- ── GROUP 4: MELEE WHOOSH ────────────────────────────────────────────────

	Katana = {
		Fire  = "rbxassetid://91828523147155",
		Pitch = 1.0,
	},
	CurvedKnife = {
		Fire  = "rbxassetid://91828523147155",  -- same as Katana
		Pitch = 1.2,
	},
	Flamberge = {
		Fire  = "rbxassetid://91828523147155",  -- same as Katana
		Pitch = 0.85,
	},
	BaseballBat = {
		Fire  = "rbxassetid://91828523147155",  -- same as Katana (blunt swing)
		Pitch = 0.7,
	},

	-- ── GROUP 5: EXPLOSIVE THROW ─────────────────────────────────────────────

	HandGrenade = {
		Fire  = "rbxassetid://98015644153900",
		Pitch = 1.0,
	},
	StunGrenade = {
		Fire  = "rbxassetid://98015644153900",  -- same as HandGrenade
		Pitch = 1.15,
	},
	Bomb = {
		Fire  = "rbxassetid://98015644153900",  -- same as HandGrenade
		Pitch = 0.85,
	},
	Phoenix = {
		Fire  = "rbxassetid://98015644153900",  -- same as HandGrenade
		Pitch = 0.9,
	},

	-- ── GROUP 6: PLACEMENT CLICK ─────────────────────────────────────────────

	ProximityMine = {
		Fire  = "rbxassetid://98015644153900",
		Pitch = 1.0,
	},
	StunMine = {
		Fire  = "rbxassetid://98015644153900",  -- same as ProximityMine
		Pitch = 1.1,
	},

	-- ── GROUP 7: LAUNCHER ────────────────────────────────────────────────────

	RocketLauncher = {
		Fire  = "rbxassetid://82948223486774",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
	BombLauncher = {
		Fire  = "rbxassetid://82948223486774",  -- same as RocketLauncher
		Empty = "rbxassetid://89343784634356",
		Pitch = 0.85,
	},

	-- ── UNIQUE SOUNDS ────────────────────────────────────────────────────────

	SawedOff = {
		Fire  = "rbxassetid://100645278320904",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
	Harpoon = {
		Fire  = "rbxassetid://99433118923656",
		Pitch = 1.0,
	},
	Propulsors = {
		Fire  = "rbxassetid://106934770379455",
		Pitch = 1.0,
	},
	GlaiveGun = {
		Fire  = "rbxassetid://76224678355390",
		Empty = "rbxassetid://89343784634356",
		Pitch = 1.0,
	},
}

return WeaponSounds
