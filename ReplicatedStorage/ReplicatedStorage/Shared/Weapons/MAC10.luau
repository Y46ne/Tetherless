local MAC10 = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

MAC10.Stats = {
	["Damage"] = 10,
	["Headshot Multiplier"] = 2,
	["Capacity"] = 56,
	["Fire-Rate"] = 0.033,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "One-Handed", "Full-Automatic", "Hit-Scan" },
	Power = 10,
	HeadshotMultiplier = 2,
	Magazine = 56,
	FireRate = 0.033,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = true,
	Category = "SMG",
	Spread = 0.06,
}

local function applySpread(direction, spread)
	local x = (math.random() - 0.5) * 2 * spread
	local y = (math.random() - 0.5) * 2 * spread
	return (direction + Vector3.new(x, y, 0)).Unit
end

function MAC10.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function MAC10.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = applySpread(payload.Direction, MAC10.Stats.Spread)
	local rayResult = RaycastUtils.Raycast(origin, direction * 900, { attacker.Character })

	if rayResult then
		local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local damage = MAC10.Stats.Power
			local isHeadshot = rayResult.Instance.Name == "Head"
			if isHeadshot then
				damage = damage * MAC10.Stats.HeadshotMultiplier
			end

			onHitCallback(rayResult, damage, isHeadshot)
		end
	end
end

return MAC10
