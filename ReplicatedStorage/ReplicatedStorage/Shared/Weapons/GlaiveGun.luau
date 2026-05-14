-- GlaiveGun
-- One-handed burst-fire SMG. Each trigger pull fires a 6-shot burst server-side.
-- Magazine counts trigger pulls (6 bursts = 36 shots total before empty).

local GlaiveGun = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

local BURST_SIZE = 6
local BURST_DELAY = 0.02 -- seconds between each shot in the burst

GlaiveGun.Stats = {
	DisplayName = "Glaive Gun",
	FireRate = 0.4, -- cooldown between bursts
	Magazine = 6,   -- 6 trigger pulls × 6 shots = 36 total
	Category = "Pistol",
	DualWieldable = true,
	Traits = { "One-Handed", "Burst Fire", "Hit-Scan" },
	Power = 18.75,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	Spread = 0.025, -- slight spread within the burst
}

function GlaiveGun.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function GlaiveGun.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local baseDirection = payload.Direction.Unit

	-- Fire BURST_SIZE shots with a small delay between each.
	-- All share the same base direction; each gets slight independent spread.
	for i = 1, BURST_SIZE do
		task.delay((i - 1) * BURST_DELAY, function()
			if not attacker.Character then return end

			local spread = GlaiveGun.Stats.Spread
			local randX = (math.random() - 0.5) * 2 * spread
			local randY = (math.random() - 0.5) * 2 * spread
			local right = baseDirection:Cross(Vector3.new(0, 1, 0))
			if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) end
			right = right.Unit
			local up = right:Cross(baseDirection).Unit
			local direction = (baseDirection + right * randX + up * randY).Unit

			local rayResult = RaycastUtils.Raycast(origin, direction * 300, { attacker.Character })
			if rayResult and rayResult.Instance then
				local isHeadshot = rayResult.Instance.Name == "Head"
				local damage = GlaiveGun.Stats.Power * (isHeadshot and GlaiveGun.Stats.HeadshotMultiplier or 1)
				onHitCallback(rayResult, damage, isHeadshot)
			end
		end)
	end
end

return GlaiveGun
