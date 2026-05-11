local AK = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

AK.Stats = {
	["Damage"] = 25,
	["Headshot Multiplier"] = 4,
	["Capacity"] = 30,
	["Fire-Rate"] = 0.1,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "Two-Handed", "Full-Automatic", "Hit-Scan" },
	Power = 25,
	HeadshotMultiplier = 4,
	Magazine = 30,
	FireRate = 0.1,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = false,
	Category = "Rifle",
}

function AK.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function AK.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction
	local rayResult = RaycastUtils.Raycast(origin, direction * 1000, { attacker.Character })

	if rayResult then
		local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local damage = AK.Stats.Power
			local isHeadshot = rayResult.Instance.Name == "Head"
			if isHeadshot then
				damage = damage * AK.Stats.HeadshotMultiplier
			end

			onHitCallback(rayResult, damage, isHeadshot)
		end
	end
end

return AK
