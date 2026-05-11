local SawedOff = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

SawedOff.Stats = {
	["Damage"] = 10,
	["Headshot Multiplier"] = 2,
	["Capacity"] = 2,
	["Fire-Rate"] = 0.4,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "One-Handed", "Semi-Automatic", "Hit-Scan" },
	Power = 10,
	HeadshotMultiplier = 2,
	Magazine = 2,
	FireRate = 0.4,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = true,
	Category = "Shotgun",
	PelletCount = 8,
	Spread = 0.12,
	PelletRange = 250,
}

local function getSpreadDirection(direction, spread)
	local offsetX = (math.random() - 0.5) * 2 * spread
	local offsetY = (math.random() - 0.5) * 2 * spread
	return (direction + Vector3.new(offsetX, offsetY, 0)).Unit
end

function SawedOff.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function SawedOff.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local baseDirection = payload.Direction.Unit
	local pellets = SawedOff.Stats.PelletCount

	for _ = 1, pellets do
		local pelletDirection = getSpreadDirection(baseDirection, SawedOff.Stats.Spread)
		local rayResult =
			RaycastUtils.Raycast(origin, pelletDirection * SawedOff.Stats.PelletRange, { attacker.Character })

		if rayResult then
			local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local damage = SawedOff.Stats.Power
				local isHeadshot = rayResult.Instance.Name == "Head"
				if isHeadshot then
					damage = damage * SawedOff.Stats.HeadshotMultiplier
				end

				onHitCallback(rayResult, damage, isHeadshot)
			end
		end
	end
end

return SawedOff
