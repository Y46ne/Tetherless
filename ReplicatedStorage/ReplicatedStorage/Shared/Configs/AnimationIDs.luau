local AnimationIDs = {
	-- Movement
	["Sliding"] = {
		id = "rbxassetid://138444642108422",
	},
	["LeftWallRun"] = {
		id = "rbxassetid://79246724030244",
	},
	["RightWallRun"] = {
		id = "rbxassetid://73620320090733",
	},

	-- Movement states
	["Crouch"] = {
		id = "rbxassetid://85625547145850",
	},

	-- Third-person arm poses (visible to other players via Roblox animator replication).
	-- Replace the placeholder IDs with your actual animation asset IDs.
	["RightArmWeapon"] = {
		id = "rbxassetid://112050675847805",  -- right arm raised/holding, left arm idle
	},
	["LeftArmWeapon"] = {
		id = "rbxassetid://108081736908414",  -- left arm raised/holding, right arm idle
	},
	["BothArmsWeapon"] = {
		id = "rbxassetid://125230981036891",  -- both arms raised (two-handed or dual-wield)
	},
}

return AnimationIDs
